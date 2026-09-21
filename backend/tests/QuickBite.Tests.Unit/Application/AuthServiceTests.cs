using FluentAssertions;
using Moq;
using QuickBite.Application.Authentication;
using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Authentication.Models;
using QuickBite.Application.Configuration;
using QuickBite.Application.Email;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;

namespace QuickBite.Tests.Unit.Application;

public class AuthServiceTests
{
    private static readonly ClientInfo Client = new("127.0.0.1", "test-agent");

    private readonly Mock<IUserRepository> _users = new();
    private readonly Mock<IDeliveryPersonRepository> _deliveryPeople = new();
    private readonly Mock<IAuditRepository> _audits = new();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IPasswordHasher> _passwordHasher = new();
    private readonly Mock<ISecureTokenGenerator> _tokenGenerator = new();
    private readonly Mock<IJwtTokenGenerator> _jwtTokenGenerator = new();
    private readonly Mock<IEmailService> _emailService = new();

    public AuthServiceTests()
    {
        _unitOfWork.SetupGet(u => u.Users).Returns(_users.Object);
        _unitOfWork.SetupGet(u => u.DeliveryPeople).Returns(_deliveryPeople.Object);
        _unitOfWork.SetupGet(u => u.Audits).Returns(_audits.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);

        _passwordHasher.Setup(h => h.Hash(It.IsAny<string>())).Returns("hashed-password");
        _passwordHasher.Setup(h => h.Verify(It.IsAny<string>(), It.IsAny<string>())).Returns(false);

        _tokenGenerator.Setup(t => t.Generate()).Returns("raw-token");
        _tokenGenerator.Setup(t => t.Hash(It.IsAny<string>())).Returns("hashed-token");

        _jwtTokenGenerator
            .Setup(j => j.GenerateAccessToken(It.IsAny<User>()))
            .Returns(new AccessToken("access-token", DateTime.UtcNow.AddMinutes(60)));

        _emailService
            .Setup(e => e.SendWelcomeEmailAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
        _emailService
            .Setup(e => e.SendPasswordResetEmailAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .Returns(Task.CompletedTask);
    }

    private AuthService CreateService()
    {
        return new AuthService(
            _unitOfWork.Object,
            _passwordHasher.Object,
            _tokenGenerator.Object,
            _jwtTokenGenerator.Object,
            _emailService.Object,
            new JwtSettings { RefreshTokenExpirationDays = 7, AccessTokenExpirationMinutes = 60 });
    }

    [Fact]
    public async Task RegisterAsync_CreaUsuarioYEnviaBienvenida()
    {
        var request = new RegisterRequest
        {
            Nombre = "Ana",
            Email = "Ana@QuickBite.com",
            Password = "Admin123!",
            Rol = "cliente"
        };

        var response = await CreateService().RegisterAsync(request);

        response.Email.Should().Be("ana@quickbite.com");
        response.Nombre.Should().Be("Ana");
        response.Rol.Should().Be("cliente");
        _users.Verify(u => u.AddAsync(It.Is<User>(x => x.Rol == UserRole.Cliente && x.PasswordHash == "hashed-password"), It.IsAny<CancellationToken>()), Times.Once);
        _deliveryPeople.Verify(d => d.AddAsync(It.IsAny<DeliveryPerson>(), It.IsAny<CancellationToken>()), Times.Never);
        _emailService.Verify(e => e.SendWelcomeEmailAsync("ana@quickbite.com", "Ana", It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task RegisterAsync_ConEmailExistente_LanzaConflict()
    {
        _users.Setup(u => u.GetByEmailAsync("ana@quickbite.com", It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Email = "ana@quickbite.com" });

        var request = new RegisterRequest { Nombre = "Ana", Email = "ana@quickbite.com", Password = "Admin123!", Rol = "cliente" };

        var act = () => CreateService().RegisterAsync(request);

        await act.Should().ThrowAsync<ConflictException>();
    }

    [Fact]
    public async Task RegisterAsync_ConRolRepartidor_CreaRepartidorInactivo()
    {
        DeliveryPerson? captured = null;
        _deliveryPeople
            .Setup(d => d.AddAsync(It.IsAny<DeliveryPerson>(), It.IsAny<CancellationToken>()))
            .Callback<DeliveryPerson, CancellationToken>((d, _) => captured = d)
            .Returns(Task.CompletedTask);

        var request = new RegisterRequest { Nombre = "Rep", Email = "rep@quickbite.com", Password = "Admin123!", Rol = "repartidor" };

        var response = await CreateService().RegisterAsync(request);

        response.Rol.Should().Be("repartidor");
        captured.Should().NotBeNull();
        captured!.EstadoDisponibilidad.Should().Be(DeliveryPersonStatus.Inactivo);
    }

    [Fact]
    public async Task LoginAsync_ConCredencialesValidas_DevuelveTokensYActualizaUltimoLogin()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "ana@quickbite.com", PasswordHash = "hashed-password", Activo = true };
        _users.Setup(u => u.GetByEmailAsync("ana@quickbite.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _passwordHasher.Setup(h => h.Verify("Admin123!", "hashed-password")).Returns(true);

        var response = await CreateService().LoginAsync(new LoginRequest { Email = "ana@quickbite.com", Password = "Admin123!" }, Client);

        response.AccessToken.Should().Be("access-token");
        response.RefreshToken.Should().Be("raw-token");
        response.ExpiresIn.Should().BeGreaterThan(0);
        user.UltimoLogin.Should().NotBeNull();
        user.IntentosFallidos.Should().Be(0);
        _users.Verify(u => u.AddRefreshTokenAsync(It.Is<RefreshToken>(t => t.TokenHash == "hashed-token" && t.IpOrigen == "127.0.0.1"), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task LoginAsync_ConCredencialesValidas_RegistraAuditoriaDeSesion()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "ana@quickbite.com", PasswordHash = "hashed-password", Activo = true };
        _users.Setup(u => u.GetByEmailAsync("ana@quickbite.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);
        _passwordHasher.Setup(h => h.Verify("Admin123!", "hashed-password")).Returns(true);

        AuditAction? captured = null;
        _audits
            .Setup(a => a.AddAsync(It.IsAny<AuditAction>(), It.IsAny<CancellationToken>()))
            .Callback<AuditAction, CancellationToken>((action, _) => captured = action)
            .Returns(Task.CompletedTask);

        await CreateService().LoginAsync(new LoginRequest { Email = "ana@quickbite.com", Password = "Admin123!" }, Client);

        captured.Should().NotBeNull();
        captured!.UsuarioId.Should().Be(user.Id);
        captured.EntidadId.Should().Be(user.Id);
        captured.Accion.Should().Be("login");
        captured.Entidad.Should().Be("sesion");
        captured.IpOrigen.Should().Be("127.0.0.1");
        captured.UserAgent.Should().Be("test-agent");
    }

    [Fact]
    public async Task LoginAsync_ConPasswordIncorrecta_IncrementaIntentosYLanzaUnauthorized()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "ana@quickbite.com", PasswordHash = "hashed-password", Activo = true, IntentosFallidos = 1 };
        _users.Setup(u => u.GetByEmailAsync("ana@quickbite.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var act = () => CreateService().LoginAsync(new LoginRequest { Email = "ana@quickbite.com", Password = "mala" }, Client);

        await act.Should().ThrowAsync<UnauthorizedException>();
        user.IntentosFallidos.Should().Be(2);
        user.BloqueadoHasta.Should().BeNull();
    }

    [Fact]
    public async Task LoginAsync_AlAlcanzarCincoIntentos_BloqueaLaCuenta()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "ana@quickbite.com", PasswordHash = "hashed-password", Activo = true, IntentosFallidos = 4 };
        _users.Setup(u => u.GetByEmailAsync("ana@quickbite.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var act = () => CreateService().LoginAsync(new LoginRequest { Email = "ana@quickbite.com", Password = "mala" }, Client);

        await act.Should().ThrowAsync<UnauthorizedException>();
        user.BloqueadoHasta.Should().NotBeNull();
        user.BloqueadoHasta.Should().BeAfter(DateTime.UtcNow);
    }

    [Fact]
    public async Task LoginAsync_ConCuentaBloqueada_LanzaForbidden()
    {
        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = "ana@quickbite.com",
            PasswordHash = "hashed-password",
            Activo = true,
            BloqueadoHasta = DateTime.UtcNow.AddMinutes(10)
        };
        _users.Setup(u => u.GetByEmailAsync("ana@quickbite.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var act = () => CreateService().LoginAsync(new LoginRequest { Email = "ana@quickbite.com", Password = "Admin123!" }, Client);

        await act.Should().ThrowAsync<ForbiddenException>();
    }

    [Fact]
    public async Task RefreshAsync_ConTokenValido_RotaElToken()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "ana@quickbite.com", Activo = true };
        var stored = new RefreshToken { UsuarioId = user.Id, TokenHash = "hashed-token", ExpiraEn = DateTime.UtcNow.AddDays(1), Revocado = false };
        _users.Setup(u => u.GetRefreshTokenByHashAsync("hashed-token", It.IsAny<CancellationToken>())).ReturnsAsync(stored);
        _users.Setup(u => u.GetByIdAsync(user.Id, It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var response = await CreateService().RefreshAsync(new RefreshRequest { RefreshToken = "raw-token" }, Client);

        stored.Revocado.Should().BeTrue();
        response.AccessToken.Should().Be("access-token");
        response.RefreshToken.Should().Be("raw-token");
        _users.Verify(u => u.AddRefreshTokenAsync(It.IsAny<RefreshToken>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task RefreshAsync_ConTokenRevocado_LanzaValidation()
    {
        var stored = new RefreshToken { UsuarioId = Guid.NewGuid(), TokenHash = "hashed-token", ExpiraEn = DateTime.UtcNow.AddDays(1), Revocado = true };
        _users.Setup(u => u.GetRefreshTokenByHashAsync("hashed-token", It.IsAny<CancellationToken>())).ReturnsAsync(stored);

        var act = () => CreateService().RefreshAsync(new RefreshRequest { RefreshToken = "raw-token" }, Client);

        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task LogoutAsync_RevocaElToken()
    {
        var stored = new RefreshToken { UsuarioId = Guid.NewGuid(), TokenHash = "hashed-token", ExpiraEn = DateTime.UtcNow.AddDays(1), Revocado = false };
        _users.Setup(u => u.GetRefreshTokenByHashAsync("hashed-token", It.IsAny<CancellationToken>())).ReturnsAsync(stored);

        await CreateService().LogoutAsync(new LogoutRequest { RefreshToken = "raw-token" });

        stored.Revocado.Should().BeTrue();
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ForgotPasswordAsync_ConEmailInexistente_DevuelveMensajeGenericoSinEnviar()
    {
        _users.Setup(u => u.GetByEmailAsync("nadie@quickbite.com", It.IsAny<CancellationToken>())).ReturnsAsync((User?)null);

        var response = await CreateService().ForgotPasswordAsync(new ForgotPasswordRequest { Email = "nadie@quickbite.com" });

        response.Message.Should().NotBeNullOrWhiteSpace();
        _users.Verify(u => u.AddPasswordResetTokenAsync(It.IsAny<PasswordResetToken>(), It.IsAny<CancellationToken>()), Times.Never);
        _emailService.Verify(e => e.SendPasswordResetEmailAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task ForgotPasswordAsync_ConEmailExistente_GuardaTokenYEnviaCorreo()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "ana@quickbite.com", Nombre = "Ana", Activo = true };
        _users.Setup(u => u.GetByEmailAsync("ana@quickbite.com", It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var response = await CreateService().ForgotPasswordAsync(new ForgotPasswordRequest { Email = "ana@quickbite.com" });

        response.Message.Should().NotBeNullOrWhiteSpace();
        _users.Verify(u => u.AddPasswordResetTokenAsync(It.Is<PasswordResetToken>(t => t.TokenHash == "hashed-token"), It.IsAny<CancellationToken>()), Times.Once);
        _emailService.Verify(e => e.SendPasswordResetEmailAsync("ana@quickbite.com", "Ana", "raw-token", It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task ResetPasswordAsync_ConTokenValido_ActualizaElHashYMarcaUsado()
    {
        var user = new User { Id = Guid.NewGuid(), Email = "ana@quickbite.com", PasswordHash = "viejo", Activo = true, IntentosFallidos = 3 };
        var resetToken = new PasswordResetToken { UsuarioId = user.Id, TokenHash = "hashed-token", ExpiraEn = DateTime.UtcNow.AddMinutes(30), Usado = false };
        _users.Setup(u => u.GetPasswordResetTokenByHashAsync("hashed-token", It.IsAny<CancellationToken>())).ReturnsAsync(resetToken);
        _users.Setup(u => u.GetByIdAsync(user.Id, It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var response = await CreateService().ResetPasswordAsync(new ResetPasswordRequest { Token = "raw-token", NewPassword = "Nueva123!" });

        user.PasswordHash.Should().Be("hashed-password");
        user.IntentosFallidos.Should().Be(0);
        resetToken.Usado.Should().BeTrue();
        response.Message.Should().Contain("restablecida");
    }

    [Fact]
    public async Task ResetPasswordAsync_ConTokenExpirado_LanzaValidation()
    {
        var resetToken = new PasswordResetToken { UsuarioId = Guid.NewGuid(), TokenHash = "hashed-token", ExpiraEn = DateTime.UtcNow.AddMinutes(-1), Usado = false };
        _users.Setup(u => u.GetPasswordResetTokenByHashAsync("hashed-token", It.IsAny<CancellationToken>())).ReturnsAsync(resetToken);

        var act = () => CreateService().ResetPasswordAsync(new ResetPasswordRequest { Token = "raw-token", NewPassword = "Nueva123!" });

        await act.Should().ThrowAsync<ValidationException>();
    }
}
