using FluentAssertions;
using Moq;
using QuickBite.Application.Admin;
using QuickBite.Application.Admin.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;

namespace QuickBite.Tests.Unit.Application;

public class AdminDeliveryServiceTests
{
    private readonly Mock<IUserRepository> _users = new();
    private readonly Mock<IDeliveryPersonRepository> _deliveryPeople = new();
    private readonly Mock<IOrderRepository> _orders = new();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();

    public AdminDeliveryServiceTests()
    {
        _unitOfWork.SetupGet(u => u.Users).Returns(_users.Object);
        _unitOfWork.SetupGet(u => u.DeliveryPeople).Returns(_deliveryPeople.Object);
        _unitOfWork.SetupGet(u => u.Orders).Returns(_orders.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);
    }

    private AdminDeliveryService CreateService() => new(_unitOfWork.Object);

    private static DeliveryPerson BuildDeliveryPerson(Guid userId, DeliveryPersonStatus estado = DeliveryPersonStatus.Inactivo) =>
        new()
        {
            UsuarioId = userId,
            EstadoDisponibilidad = estado,
            Vehiculo = "moto",
            EntregasCompletadas = 3,
            FechaAlta = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc),
            Usuario = new User { Nombre = "Pedro", Email = "pedro@quickbite.com", Telefono = "555" }
        };

    [Fact]
    public async Task CreateAsync_UsuarioNoExiste_LanzaValidation()
    {
        _users.Setup(u => u.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync((User?)null);

        var act = () => CreateService().CreateAsync(new CreateDeliveryPersonRequest { UsuarioId = Guid.NewGuid() });

        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task CreateAsync_UsuarioSinRolRepartidor_LanzaValidation()
    {
        _users.Setup(u => u.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = Guid.NewGuid(), Rol = UserRole.Cliente });

        var act = () => CreateService().CreateAsync(new CreateDeliveryPersonRequest { UsuarioId = Guid.NewGuid() });

        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task CreateAsync_UsuarioYaRegistrado_LanzaConflict()
    {
        _users.Setup(u => u.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = Guid.NewGuid(), Rol = UserRole.Repartidor });
        _deliveryPeople.Setup(d => d.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(BuildDeliveryPerson(Guid.NewGuid()));

        var act = () => CreateService().CreateAsync(new CreateDeliveryPersonRequest { UsuarioId = Guid.NewGuid() });

        await act.Should().ThrowAsync<ConflictException>();
    }

    [Fact]
    public async Task CreateAsync_Valido_CreaConEstadoInactivo()
    {
        var userId = Guid.NewGuid();
        _users.Setup(u => u.GetByIdAsync(userId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new User { Id = userId, Nombre = "Pedro", Email = "pedro@quickbite.com", Rol = UserRole.Repartidor });
        _deliveryPeople.Setup(d => d.GetByIdAsync(userId, It.IsAny<CancellationToken>())).ReturnsAsync((DeliveryPerson?)null);
        DeliveryPerson? captured = null;
        _deliveryPeople.Setup(d => d.AddAsync(It.IsAny<DeliveryPerson>(), It.IsAny<CancellationToken>()))
            .Callback<DeliveryPerson, CancellationToken>((d, _) => captured = d)
            .Returns(Task.CompletedTask);

        var response = await CreateService().CreateAsync(new CreateDeliveryPersonRequest { UsuarioId = userId, Vehiculo = " moto " });

        response.EstadoDisponibilidad.Should().Be("inactivo");
        captured.Should().NotBeNull();
        captured!.Vehiculo.Should().Be("moto");
        captured.UsuarioId.Should().Be(userId);
    }

    [Fact]
    public async Task UpdateAsync_EstadoInvalido_LanzaValidation()
    {
        var id = Guid.NewGuid();
        _deliveryPeople.Setup(d => d.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(BuildDeliveryPerson(id));

        var act = () => CreateService().UpdateAsync(id, new UpdateDeliveryPersonRequest { EstadoDisponibilidad = "volando" });

        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task UpdateAsync_DisponibleConPedidosActivos_LanzaBusinessRule()
    {
        var id = Guid.NewGuid();
        _deliveryPeople.Setup(d => d.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(BuildDeliveryPerson(id));
        _orders.Setup(o => o.HasActiveOrdersAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(true);

        var act = () => CreateService().UpdateAsync(id, new UpdateDeliveryPersonRequest { EstadoDisponibilidad = "disponible" });

        await act.Should().ThrowAsync<BusinessRuleException>();
    }

    [Fact]
    public async Task UpdateAsync_DisponibleSinPedidosActivos_ActualizaEstado()
    {
        var id = Guid.NewGuid();
        var dp = BuildDeliveryPerson(id);
        _deliveryPeople.Setup(d => d.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(dp);
        _orders.Setup(o => o.HasActiveOrdersAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(false);

        var response = await CreateService().UpdateAsync(id, new UpdateDeliveryPersonRequest { Vehiculo = "furgoneta", EstadoDisponibilidad = "disponible" });

        response.EstadoDisponibilidad.Should().Be("disponible");
        dp.EstadoDisponibilidad.Should().Be(DeliveryPersonStatus.Disponible);
        dp.Vehiculo.Should().Be("furgoneta");
    }

    [Fact]
    public async Task DeactivateAsync_ConPedidosActivos_LanzaBusinessRule()
    {
        var id = Guid.NewGuid();
        _deliveryPeople.Setup(d => d.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(BuildDeliveryPerson(id, DeliveryPersonStatus.Disponible));
        _orders.Setup(o => o.HasActiveOrdersAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(true);

        var act = () => CreateService().DeactivateAsync(id);

        await act.Should().ThrowAsync<BusinessRuleException>();
    }

    [Fact]
    public async Task DeactivateAsync_Valido_PoneInactivo()
    {
        var id = Guid.NewGuid();
        var dp = BuildDeliveryPerson(id, DeliveryPersonStatus.Disponible);
        _deliveryPeople.Setup(d => d.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(dp);
        _orders.Setup(o => o.HasActiveOrdersAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(false);

        var response = await CreateService().DeactivateAsync(id);

        response.EstadoDisponibilidad.Should().Be("inactivo");
        dp.EstadoDisponibilidad.Should().Be(DeliveryPersonStatus.Inactivo);
    }

    [Fact]
    public async Task GetHistoryAsync_RepartidorNoExiste_LanzaNotFound()
    {
        _deliveryPeople.Setup(d => d.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync((DeliveryPerson?)null);

        var act = () => CreateService().GetHistoryAsync(Guid.NewGuid(), 1, 10);

        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task GetHistoryAsync_CalculaTiempoDeEntrega()
    {
        var id = Guid.NewGuid();
        _deliveryPeople.Setup(d => d.GetByIdAsync(id, It.IsAny<CancellationToken>())).ReturnsAsync(BuildDeliveryPerson(id));
        var enCamino = new DateTime(2026, 9, 1, 12, 0, 0, DateTimeKind.Utc);
        _orders.Setup(o => o.GetDeliveredByDeliveryPersonPagedAsync(id, 1, 10, It.IsAny<CancellationToken>()))
            .ReturnsAsync((new List<Order>
            {
                new() { NumeroPedido = "QB-100", Total = 45m, EnCaminoEn = enCamino, EntregadoEn = enCamino.AddMinutes(25), Cliente = new User { Nombre = "Ana" } }
            }, 1));

        var result = await CreateService().GetHistoryAsync(id, 1, 10);

        result.Total.Should().Be(1);
        result.Data.Should().ContainSingle().Which.TiempoEntregaMinutos.Should().Be(25);
    }

    [Fact]
    public async Task ListAsync_ConEstadoInvalido_LanzaValidation()
    {
        var act = () => CreateService().ListAsync("inexistente", 1, 10);

        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task GetAvailableUsersAsync_DevuelveSoloRepartidoresSinRegistro()
    {
        var conRegistro = Guid.NewGuid();
        var sinRegistro = Guid.NewGuid();
        _users.Setup(u => u.GetByRoleAsync(UserRole.Repartidor, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<User>
            {
                new() { Id = conRegistro, Nombre = "Pedro", Email = "pedro@quickbite.com", Rol = UserRole.Repartidor },
                new() { Id = sinRegistro, Nombre = "Luis", Email = "luis@quickbite.com", Rol = UserRole.Repartidor }
            });
        _deliveryPeople.Setup(d => d.GetPagedAsync(null, 1, 1000, It.IsAny<CancellationToken>()))
            .ReturnsAsync((new List<DeliveryPerson> { new() { UsuarioId = conRegistro } }, 1));

        var result = await CreateService().GetAvailableUsersAsync();

        result.Should().ContainSingle().Which.UsuarioId.Should().Be(sinRegistro);
    }

    [Fact]
    public async Task GetAvailableUsersAsync_ConsultaUsuariosRolRepartidor()
    {
        var userId = Guid.NewGuid();
        _users.Setup(u => u.GetByRoleAsync(UserRole.Repartidor, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<User>
            {
                new() { Id = userId, Nombre = "Ana", Email = "ana@quickbite.com", Rol = UserRole.Repartidor }
            });
        _deliveryPeople.Setup(d => d.GetPagedAsync(null, 1, 1000, It.IsAny<CancellationToken>()))
            .ReturnsAsync((new List<DeliveryPerson>(), 0));

        await CreateService().GetAvailableUsersAsync();

        _users.Verify(u => u.GetByRoleAsync(UserRole.Repartidor, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetAvailableUsersAsync_ExponeNombreYEmail()
    {
        var userId = Guid.NewGuid();
        _users.Setup(u => u.GetByRoleAsync(UserRole.Repartidor, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<User>
            {
                new() { Id = userId, Nombre = "Marta", Email = "marta@quickbite.com", Rol = UserRole.Repartidor }
            });
        _deliveryPeople.Setup(d => d.GetPagedAsync(null, 1, 1000, It.IsAny<CancellationToken>()))
            .ReturnsAsync((new List<DeliveryPerson>(), 0));

        var result = await CreateService().GetAvailableUsersAsync();

        result.Should().ContainSingle().Which.Nombre.Should().Be("Marta");
        result.Should().ContainSingle().Which.Email.Should().Be("marta@quickbite.com");
    }
}