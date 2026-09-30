using FluentAssertions;
using Moq;
using QuickBite.Application.Admin;
using QuickBite.Application.Admin.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Tests.Unit.Application;

public class AdminUserServiceTests
{
    private readonly Mock<IUserRepository> _users = new();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();

    public AdminUserServiceTests()
    {
        _unitOfWork.SetupGet(u => u.Users).Returns(_users.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);
    }

    private AdminUserService CreateService() => new(_unitOfWork.Object);

    private static User BuildUser(
        Guid? id = null,
        UserRole rol = UserRole.Cliente,
        bool activo = true,
        DateTime? ultimoLogin = null) =>
        new()
        {
            Id = id ?? Guid.NewGuid(),
            Nombre = "Ana",
            Email = "ana@quickbite.com",
            Telefono = "555",
            Rol = rol,
            Activo = activo,
            UltimoLogin = ultimoLogin,
            CreadoEn = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            ActualizadoEn = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
        };

    [Fact]
    public async Task ListAsync_ConRolInvalido_LanzaValidation()
    {
        var act = () => CreateService().ListAsync(null, "repartidon", null, 1, 10);

        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task ListAsync_ConFiltrosPasaUsuarioRepository()
    {
        var user = BuildUser();
        _users.Setup(u => u.GetPagedAsync(
                It.IsAny<string?>(), It.IsAny<UserRole?>(), It.IsAny<bool?>(), 1, 10, It.IsAny<CancellationToken>()))
            .ReturnsAsync(([user], 1));

        var result = await CreateService().ListAsync("ana", "cliente", true, 1, 10);

        result.Total.Should().Be(1);
        result.Data[0].Nombre.Should().Be("Ana");
        result.Data[0].Rol.Should().Be("cliente");
        result.Data[0].Activo.Should().BeTrue();
        _users.Verify(u => u.GetPagedAsync(
            "ana", UserRole.Cliente, true, 1, 10, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetByIdAsync_UsuarioInexistente_LanzaNotFound()
    {
        _users.Setup(u => u.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync((User?)null);

        var act = () => CreateService().GetByIdAsync(Guid.NewGuid());

        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task GetByIdAsync_DevuelveDetalleConVehiculoDeRepartidor()
    {
        var user = BuildUser(rol: UserRole.Repartidor);
        user.Repartidor = new DeliveryPerson { Vehiculo = "moto", EntregasCompletadas = 4 };
        _users.Setup(u => u.GetByIdAsync(user.Id, It.IsAny<CancellationToken>())).ReturnsAsync(user);

        var detail = await CreateService().GetByIdAsync(user.Id);

        detail.VehiculoRepartidor.Should().Be("moto");
        detail.EntregasCompletadas.Should().Be(4);
        detail.Rol.Should().Be("repartidor");
    }

    [Fact]
    public async Task UpdateRoleAsync_CuentaPropia_LanzaForbidden()
    {
        var currentUser = BuildUser();
        _users.Setup(u => u.GetByIdAsync(currentUser.Id, It.IsAny<CancellationToken>())).ReturnsAsync(currentUser);

        var act = () => CreateService().UpdateRoleAsync(
            currentUser.Id,
            new UpdateUserRoleRequest { Rol = "administrador" },
            currentUser.Id);

        await act.Should().ThrowAsync<ForbiddenException>();
    }

    [Fact]
    public async Task UpdateRoleAsync_ConRolInvalido_LanzaValidation()
    {
        var target = BuildUser();
        _users.Setup(u => u.GetByIdAsync(target.Id, It.IsAny<CancellationToken>())).ReturnsAsync(target);

        var act = () => CreateService().UpdateRoleAsync(
            target.Id,
            new UpdateUserRoleRequest { Rol = "jefe" },
            Guid.NewGuid());

        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task UpdateRoleAsync_RepartidorVinculado_LanzaBusinessRule()
    {
        var target = BuildUser(rol: UserRole.Repartidor);
        target.Repartidor = new DeliveryPerson();
        _users.Setup(u => u.GetByIdAsync(target.Id, It.IsAny<CancellationToken>())).ReturnsAsync(target);

        var act = () => CreateService().UpdateRoleAsync(
            target.Id,
            new UpdateUserRoleRequest { Rol = "cliente" },
            Guid.NewGuid());

        await act.Should().ThrowAsync<BusinessRuleException>();
    }

    [Fact]
    public async Task UpdateRoleAsync_EsDeOtroUsuarioYValido_ActualizaRol()
    {
        var target = BuildUser(rol: UserRole.Cliente);
        _users.Setup(u => u.GetByIdAsync(target.Id, It.IsAny<CancellationToken>())).ReturnsAsync(target);

        var detail = await CreateService().UpdateRoleAsync(
            target.Id,
            new UpdateUserRoleRequest { Rol = "administrador" },
            Guid.NewGuid());

        detail.Rol.Should().Be("administrador");
        target.Rol.Should().Be(UserRole.Administrador);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateStatusAsync_CuentaPropia_LanzaForbidden()
    {
        var currentUser = BuildUser();
        _users.Setup(u => u.GetByIdAsync(currentUser.Id, It.IsAny<CancellationToken>())).ReturnsAsync(currentUser);

        var act = () => CreateService().UpdateStatusAsync(
            currentUser.Id,
            new UpdateUserStatusRequest { Activo = false },
            currentUser.Id);

        await act.Should().ThrowAsync<ForbiddenException>();
    }

    [Fact]
    public async Task UpdateStatusAsync_Desactivar_RevocaSesionesActivas()
    {
        var target = BuildUser();
        _users.Setup(u => u.GetByIdAsync(target.Id, It.IsAny<CancellationToken>())).ReturnsAsync(target);
        _users.Setup(u => u.GetActiveSessionsAsync(target.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync([
                new UserSessionInfo { SessionId = Guid.NewGuid(), UserId = target.Id },
                new UserSessionInfo { SessionId = Guid.NewGuid(), UserId = target.Id }
            ]);
        _users.Setup(u => u.RevokeSessionAsync(It.IsAny<Guid>(), target.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var detail = await CreateService().UpdateStatusAsync(
            target.Id,
            new UpdateUserStatusRequest { Activo = false },
            Guid.NewGuid());

        detail.Activo.Should().BeFalse();
        target.Activo.Should().BeFalse();
        _users.Verify(u => u.RevokeSessionAsync(It.IsAny<Guid>(), target.Id, It.IsAny<CancellationToken>()), Times.Exactly(2));
        _users.Verify(u => u.GetActiveSessionsAsync(target.Id, It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateStatusAsync_Reactivar_NoRevocaSesiones()
    {
        var target = BuildUser(activo: false);
        _users.Setup(u => u.GetByIdAsync(target.Id, It.IsAny<CancellationToken>())).ReturnsAsync(target);

        var detail = await CreateService().UpdateStatusAsync(
            target.Id,
            new UpdateUserStatusRequest { Activo = true },
            Guid.NewGuid());

        detail.Activo.Should().BeTrue();
        _users.Verify(u => u.GetActiveSessionsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()), Times.Never);
        _users.Verify(u => u.RevokeSessionAsync(It.IsAny<Guid>(), It.IsAny<Guid>(), It.IsAny<CancellationToken>()), Times.Never);
    }
}