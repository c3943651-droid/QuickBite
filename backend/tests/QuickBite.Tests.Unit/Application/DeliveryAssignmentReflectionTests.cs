using FluentAssertions;
using Moq;
using QuickBite.Application.Admin;
using QuickBite.Application.Delivery;
using QuickBite.Application.Delivery.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;

namespace QuickBite.Tests.Unit.Application;

/// El panel de admin asigna repartidores a mano. Antes esa asignación no movía el
/// estado del pedido, así que el pedido quedaba `Listo` con repartidor: para el
/// repartidor era invisible (ni en `/delivery/active`, que filtra `EnCamino`,
/// ni en `/available`, que excluye los ya asignados) y para el admin tampoco
/// aparecía como "en camino".
public class DeliveryAssignmentReflectionTests
{
    private readonly Mock<IOrderRepository> _orders = new();
    private readonly Mock<IDeliveryPersonRepository> _people = new();
    private readonly Mock<IUnitOfWork> _uow = new();

    public DeliveryAssignmentReflectionTests()
    {
        _uow.SetupGet(u => u.Orders).Returns(_orders.Object);
        _uow.SetupGet(u => u.DeliveryPeople).Returns(_people.Object);
    }

    private static Order PedidoListo() => new()
    {
        Id = Guid.NewGuid(),
        NumeroPedido = "PED-100",
        Estado = OrderStatus.Listo,
        Total = 120m,
        CreadoEn = DateTime.UtcNow,
        DireccionEntregaSnapshot = "Av. Olímpica 56, San Salvador"
    };

    [Fact]
    public async Task AdminAssignAsync_PasaElPedidoAEnCamino()
    {
        var pedido = PedidoListo();
        var repartidorId = Guid.NewGuid();
        _orders.Setup(r => r.GetByIdAsync(pedido.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(pedido);

        await new AdminOrderService(_uow.Object)
            .AssignAsync(pedido.Id, repartidorId, AssignmentOrigin.Assisted);

        _orders.Verify(
            r => r.AssignDeliveryPersonAsync(pedido.Id, repartidorId, AssignmentOrigin.Assisted, It.IsAny<CancellationToken>()),
            Times.Once);
        _orders.Verify(
            r => r.UpdateStatusAsync(pedido.Id, OrderStatus.EnCamino, It.IsAny<string?>(), It.IsAny<Guid?>(), It.IsAny<CancellationToken>()),
            Times.Once);
        // Dos guardados, no uno: la asignación se persiste antes de mover el
        // estado porque el trigger trg_validar_asignacion_repartidor solo admite
        // cambiar repartidor_id con el pedido en 'listo'. En un único
        // SaveChanges ambas columnas viajan en el mismo UPDATE y el trigger lo
        // rechaza con "Solo se pueden asignar repartidores a pedidos en estado
        // 'listo'".
        _uow.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Exactly(2));
    }

    [Fact]
    public async Task AdminAssignAsync_PedidoQueNoEstaListoNoSeAsigna()
    {
        var pedido = PedidoListo();
        pedido.Estado = OrderStatus.Preparando;
        var repartidorId = Guid.NewGuid();
        _orders.Setup(r => r.GetByIdAsync(pedido.Id, It.IsAny<CancellationToken>()))
            .ReturnsAsync(pedido);

        var act = () => new AdminOrderService(_uow.Object)
            .AssignAsync(pedido.Id, repartidorId, AssignmentOrigin.Assisted);

        await act.Should().ThrowAsync<BusinessRuleException>();
        _orders.Verify(
            r => r.AssignDeliveryPersonAsync(It.IsAny<Guid>(), It.IsAny<Guid>(), It.IsAny<AssignmentOrigin>(), It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task ActiveAsync_IncluyeClienteDireccionTelefonoEItems()
    {
        var repartidorId = Guid.NewGuid();
        var pedido = PedidoListo();
        pedido.RepartidorId = repartidorId;
        pedido.Estado = OrderStatus.EnCamino;
        pedido.Cliente = new User { Nombre = "Ana Pérez", Telefono = "+50312345678" };
        pedido.Direccion = new Address
        {
            Calle = "Av. Olímpica",
            Numero = "56",
            Referencia = "Portón azul",
            Ciudad = "San Salvador"
        };
        pedido.Items.Add(new OrderItem
        {
            Producto = new Product { Nombre = "Doble Carne" },
            Cantidad = 2
        });

        _orders.Setup(r => r.GetDeliveryOrdersAsync(repartidorId, It.IsAny<OrderStatus?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Order> { pedido });

        var respuesta = await new DeliveryService(_uow.Object).ActiveAsync(repartidorId);

        var activo = respuesta.Should().ContainSingle().Subject;
        activo.Cliente.Should().Be("Ana Pérez");
        activo.Telefono.Should().Be("+50312345678");
        activo.Direccion.Should().Be("Av. Olímpica 56, San Salvador");
        activo.Items.Should().ContainSingle().Which.Should().Be("Doble Carne");
    }

    [Fact]
    public async Task ActiveAsync_SinDatosDeEntregaNoRevienta()
    {
        var repartidorId = Guid.NewGuid();
        var pedido = PedidoListo();
        pedido.RepartidorId = repartidorId;
        pedido.Estado = OrderStatus.EnCamino;

        _orders.Setup(r => r.GetDeliveryOrdersAsync(repartidorId, It.IsAny<OrderStatus?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Order> { pedido });

        var respuesta = await new DeliveryService(_uow.Object).ActiveAsync(repartidorId);

        var activo = respuesta.Should().ContainSingle().Subject;
        activo.Cliente.Should().BeNull();
        activo.Telefono.Should().BeNull();
        activo.Items.Should().BeEmpty();
    }

    [Fact]
    public async Task AvailableAsync_SoloPedidosListoSinRepartidor()
    {
        var repartidorId = Guid.NewGuid();
        var libre = PedidoListo();
        var yaTomado = PedidoListo();
        yaTomado.Estado = OrderStatus.EnCamino;
        yaTomado.RepartidorId = Guid.NewGuid();

        _orders.Setup(r => r.GetDeliveryOrdersAsync(null, OrderStatus.Listo, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Order> { libre, yaTomado });

        var respuesta = await new DeliveryService(_uow.Object).AvailableAsync(repartidorId);

        respuesta.Should().ContainSingle().Which.Id.Should().Be(libre.Id);
    }

    [Fact]
    public async Task HistoryAsync_SoloEntregadosOCancelados()
    {
        var repartidorId = Guid.NewGuid();
        var entregado = PedidoListo();
        entregado.Estado = OrderStatus.Entregado;
        entregado.RepartidorId = repartidorId;
        var enCamino = PedidoListo();
        enCamino.Estado = OrderStatus.EnCamino;
        enCamino.RepartidorId = repartidorId;

        _orders.Setup(r => r.GetDeliveryOrdersAsync(repartidorId, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Order> { entregado, enCamino });

        var respuesta = await new DeliveryService(_uow.Object).HistoryAsync(repartidorId);

        respuesta.Should().ContainSingle().Which.Id.Should().Be(entregado.Id);
    }
}