using FluentAssertions;
using Moq;
using QuickBite.Application.Authentication;
using QuickBite.Application.Users;
using QuickBite.Application.Users.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Tests.Unit.Application;

public class UserServiceTests
{
    private readonly Mock<IUserRepository> _users = new();
    private readonly Mock<IAddressRepository> _addresses = new();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IPasswordHasher> _passwordHasher = new();
    private readonly Mock<ISecureTokenGenerator> _tokenGenerator = new();

    public UserServiceTests()
    {
        _unitOfWork.SetupGet(u => u.Users).Returns(_users.Object);
        _unitOfWork.SetupGet(u => u.Addresses).Returns(_addresses.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);

        _passwordHasher.Setup(h => h.Hash(It.IsAny<string>())).Returns("hashed-password");
        _passwordHasher.Setup(h => h.Verify(It.IsAny<string>(), It.IsAny<string>())).Returns(false);
        _tokenGenerator.Setup(t => t.Hash(It.IsAny<string>())).Returns("hashed-token");
    }

    private UserService CreateService()
    {
        return new UserService(_unitOfWork.Object, _passwordHasher.Object, _tokenGenerator.Object);
    }

    private void SetupUser(User user)
    {
        _users.Setup(u => u.GetByIdAsync(user.Id, It.IsAny<CancellationToken>())).ReturnsAsync(user);
    }

    [Fact]
    public async Task GetProfileAsync_DevuelveElPerfilConRolLegible()
    {
        var user = new User { Id = Guid.NewGuid(), Nombre = "Ana", Email = "ana@quickbite.com", Rol = UserRole.Cliente, Telefono = "555" };
        SetupUser(user);

        var profile = await CreateService().GetProfileAsync(user.Id);

        profile.Nombre.Should().Be("Ana");
        profile.Email.Should().Be("ana@quickbite.com");
        profile.Rol.Should().Be("cliente");
        profile.Telefono.Should().Be("555");
    }

    [Fact]
    public async Task UpdateProfileAsync_SoloModificaLosCamposEnviados()
    {
        var user = new User { Id = Guid.NewGuid(), Nombre = "Ana", Email = "ana@quickbite.com", Telefono = "555" };
        SetupUser(user);

        var profile = await CreateService().UpdateProfileAsync(user.Id, new UpdateProfileRequest { Nombre = "Ana María" });

        profile.Nombre.Should().Be("Ana María");
        profile.Telefono.Should().Be("555");
        _users.Verify(u => u.Update(user), Times.Once);
    }

    [Fact]
    public async Task ChangePasswordAsync_ConPasswordActualIncorrecta_LanzaValidation()
    {
        var user = new User { Id = Guid.NewGuid(), PasswordHash = "viejo" };
        SetupUser(user);

        var act = () => CreateService().ChangePasswordAsync(user.Id, new ChangePasswordRequest { CurrentPassword = "mala", NewPassword = "Nueva123!" });

        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task ChangePasswordAsync_ConPasswordActualCorrecta_ActualizaElHash()
    {
        var user = new User { Id = Guid.NewGuid(), PasswordHash = "viejo", IntentosFallidos = 2 };
        SetupUser(user);
        _passwordHasher.Setup(h => h.Verify("Actual123!", "viejo")).Returns(true);

        var response = await CreateService().ChangePasswordAsync(user.Id, new ChangePasswordRequest { CurrentPassword = "Actual123!", NewPassword = "Nueva123!" });

        user.PasswordHash.Should().Be("hashed-password");
        user.IntentosFallidos.Should().Be(0);
        response.Message.Should().Contain("actualizada");
    }

    [Fact]
    public async Task CreateAddressAsync_ConEsPredeterminada_DesmarcaLasOtras()
    {
        var userId = Guid.NewGuid();
        Address? captured = null;
        _addresses.Setup(a => a.AddAsync(It.IsAny<Address>(), It.IsAny<CancellationToken>()))
            .Callback<Address, CancellationToken>((a, _) => captured = a)
            .Returns(Task.CompletedTask);

        var response = await CreateService().CreateAddressAsync(userId, new CreateAddressRequest
        {
            Calle = "Calle 1",
            Ciudad = "Ciudad",
            EsPredeterminada = true
        });

        response.EsPredeterminada.Should().BeTrue();
        captured.Should().NotBeNull();
        _addresses.Verify(a => a.SetDefaultAsync(captured!.Id, userId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateAddressAsync_DeOtroUsuario_LanzaNotFound()
    {
        var address = new Address { Id = Guid.NewGuid(), UsuarioId = Guid.NewGuid(), Calle = "X", Ciudad = "Y" };
        _addresses.Setup(a => a.GetByIdAsync(address.Id, It.IsAny<CancellationToken>())).ReturnsAsync(address);

        var act = () => CreateService().UpdateAddressAsync(Guid.NewGuid(), address.Id, new UpdateAddressRequest { Calle = "Nueva" });

        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task DeleteAddressAsync_Propia_EliminaYGuarda()
    {
        var userId = Guid.NewGuid();
        var address = new Address { Id = Guid.NewGuid(), UsuarioId = userId, Calle = "X", Ciudad = "Y" };
        _addresses.Setup(a => a.GetByIdAsync(address.Id, It.IsAny<CancellationToken>())).ReturnsAsync(address);

        await CreateService().DeleteAddressAsync(userId, address.Id);

        _addresses.Verify(a => a.Delete(address), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task SetDefaultAddressAsync_Propia_MarcaPredeterminada()
    {
        var userId = Guid.NewGuid();
        var address = new Address { Id = Guid.NewGuid(), UsuarioId = userId, Calle = "X", Ciudad = "Y" };
        _addresses.Setup(a => a.GetByIdAsync(address.Id, It.IsAny<CancellationToken>())).ReturnsAsync(address);

        var response = await CreateService().SetDefaultAddressAsync(userId, address.Id);

        response.EsPredeterminada.Should().BeTrue();
        _addresses.Verify(a => a.SetDefaultAsync(address.Id, userId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetSessionsAsync_MarcaLaSesionActual()
    {
        var userId = Guid.NewGuid();
        var currentId = Guid.NewGuid();
        var otherId = Guid.NewGuid();
        _users.Setup(u => u.GetActiveSessionsAsync(userId, It.IsAny<CancellationToken>())).ReturnsAsync(
        [
            new UserSessionInfo { SessionId = currentId, UserId = userId, IpOrigen = "1.1.1.1" },
            new UserSessionInfo { SessionId = otherId, UserId = userId, IpOrigen = "2.2.2.2" }
        ]);
        _users.Setup(u => u.GetRefreshTokenByHashAsync("hashed-token", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new RefreshToken { Id = currentId, UsuarioId = userId });

        var sessions = await CreateService().GetSessionsAsync(userId, "raw-token");

        sessions.Single(s => s.Id == currentId).EsActual.Should().BeTrue();
        sessions.Single(s => s.Id == otherId).EsActual.Should().BeFalse();
    }

    [Fact]
    public async Task RevokeSessionAsync_CuandoNoExiste_LanzaNotFound()
    {
        _users.Setup(u => u.RevokeSessionAsync(It.IsAny<Guid>(), It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync(false);

        var act = () => CreateService().RevokeSessionAsync(Guid.NewGuid(), Guid.NewGuid());

        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task RevokeSessionAsync_CuandoExiste_Guarda()
    {
        _users.Setup(u => u.RevokeSessionAsync(It.IsAny<Guid>(), It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync(true);

        await CreateService().RevokeSessionAsync(Guid.NewGuid(), Guid.NewGuid());

        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }
}
