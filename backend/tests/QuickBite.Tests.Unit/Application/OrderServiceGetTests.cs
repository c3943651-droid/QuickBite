using FluentAssertions;
using Moq;
using QuickBite.Application.Orders;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;

namespace QuickBite.Tests.Unit.Application;

public class OrderServiceGetTests
{
    private readonly Mock<IUnitOfWork> _uow = new();
    private readonly Mock<IOrderRepository> _orders = new();

    public OrderServiceGetTests()
    {
        _uow.SetupGet(u => u.Orders).Returns(_orders.Object);
    }

    private static Order Pedido(Guid clienteId, decimal? latitud, decimal? longitud) => new()
    {
        Id = Guid.NewGuid(),
        ClienteId = clienteId,
        NumeroPedido = "QB-20261001-TEST01",
        Estado = OrderStatus.EnCamino,
        Latitud = latitud,
        Longitud = longitud,
    };

    [Fact]
    public async Task GetAsync_ConCoordenadas_LasExponeEnLaRespuesta()
    {
        var userId = Guid.NewGuid();
        var pedido = Pedido(userId, 13.7000m, -89.2100m);
        _orders.Setup(o => o.GetByIdAsync(pedido.Id, It.IsAny<CancellationToken>())).ReturnsAsync(pedido);

        var service = new OrderService(_uow.Object);
        var respuesta = await service.GetAsync(userId, pedido.Id);

        respuesta.Latitud.Should().Be(13.7000m);
        respuesta.Longitud.Should().Be(-89.2100m);
    }

    [Fact]
    public async Task GetAsync_SinCoordenadas_LasDevuelveEnNull()
    {
        var userId = Guid.NewGuid();
        var pedido = Pedido(userId, null, null);
        _orders.Setup(o => o.GetByIdAsync(pedido.Id, It.IsAny<CancellationToken>())).ReturnsAsync(pedido);

        var service = new OrderService(_uow.Object);
        var respuesta = await service.GetAsync(userId, pedido.Id);

        respuesta.Latitud.Should().BeNull();
        respuesta.Longitud.Should().BeNull();
    }

    [Fact]
    public async Task ListAsync_ConCoordenadas_LasExponeEnCadaPedido()
    {
        var userId = Guid.NewGuid();
        var pedido = Pedido(userId, 13.6929m, -89.2182m);
        _orders
            .Setup(o => o.GetOrdersAsync(userId, null, null, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<Order> { pedido });

        var service = new OrderService(_uow.Object);
        var respuesta = await service.ListAsync(userId);

        respuesta.Should().ContainSingle();
        respuesta[0].Latitud.Should().Be(13.6929m);
        respuesta[0].Longitud.Should().Be(-89.2182m);
    }
}
