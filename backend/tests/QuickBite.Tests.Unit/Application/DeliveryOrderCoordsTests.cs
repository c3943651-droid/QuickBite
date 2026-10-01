using FluentAssertions;
using Moq;
using QuickBite.Application.Delivery;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;

namespace QuickBite.Tests.Unit.Application;

public class DeliveryOrderCoordsTests
{
    private readonly Mock<IUnitOfWork> _uow = new();
    private readonly Mock<IOrderRepository> _orders = new();

    public DeliveryOrderCoordsTests()
    {
        _uow.SetupGet(u => u.Orders).Returns(_orders.Object);
    }

    private static Order Pedido(decimal? latitud, decimal? longitud, OrderStatus estado) => new()
    {
        Id = Guid.NewGuid(),
        NumeroPedido = "QB-20261001-DEL01",
        Estado = estado,
        Latitud = latitud,
        Longitud = longitud,
    };

    [Fact]
    public async Task ActiveAsync_ConCoordenadas_LasExponeParaElRepartidor()
    {
        var repartidorId = Guid.NewGuid();
        var pedido = Pedido(13.7000m, -89.2100m, OrderStatus.EnCamino);
        _orders
            .Setup(o => o.GetDeliveryOrdersAsync(repartidorId, OrderStatus.EnCamino, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Order> { pedido });

        var service = new DeliveryService(_uow.Object);
        var respuesta = await service.ActiveAsync(repartidorId);

        respuesta.Should().ContainSingle();
        respuesta[0].Latitud.Should().Be(13.7000m);
        respuesta[0].Longitud.Should().Be(-89.2100m);
    }

    [Fact]
    public async Task AvailableAsync_ConCoordenadas_LasExponeParaElRepartidor()
    {
        var repartidorId = Guid.NewGuid();
        var pedido = Pedido(13.6929m, -89.2182m, OrderStatus.Listo);
        _orders
            .Setup(o => o.GetDeliveryOrdersAsync(null, OrderStatus.Listo, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Order> { pedido });

        var service = new DeliveryService(_uow.Object);
        var respuesta = await service.AvailableAsync(repartidorId);

        respuesta.Should().ContainSingle();
        respuesta[0].Latitud.Should().Be(13.6929m);
        respuesta[0].Longitud.Should().Be(-89.2182m);
    }

    [Fact]
    public async Task HistoryAsync_SinCoordenadas_LasDevuelveEnNull()
    {
        var repartidorId = Guid.NewGuid();
        var pedido = Pedido(null, null, OrderStatus.Entregado);
        _orders
            .Setup(o => o.GetDeliveryOrdersAsync(repartidorId, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Order> { pedido });

        var service = new DeliveryService(_uow.Object);
        var respuesta = await service.HistoryAsync(repartidorId);

        respuesta.Should().ContainSingle();
        respuesta[0].Latitud.Should().BeNull();
        respuesta[0].Longitud.Should().BeNull();
    }
}
