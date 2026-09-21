using FluentAssertions;
using Moq;
using QuickBite.Application.Admin;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Shared.Dashboard;

namespace QuickBite.Tests.Unit.Application;

public class AdminOrderServiceTests
{
    private readonly Mock<IUnitOfWork> _uow = new();

    private AdminOrderService CreateService() => new(_uow.Object);

    private void CreateRepository(List<Order> orders)
    {
        var repo = new Mock<IOrderRepository>();
        repo.Setup(r => r.GetOrdersAsync(It.IsAny<Guid?>(), It.IsAny<Guid?>(), It.IsAny<OrderStatus?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(orders);
        _uow.Setup(u => u.Orders).Returns(repo.Object);
    }

    private static Order BuildOrder(string numero, OrderStatus estado, decimal total, DateTime creadoEn, string? cliente = null) => new()
    {
        NumeroPedido = numero,
        Estado = estado,
        Total = total,
        CreadoEn = creadoEn,
        Cliente = cliente is null ? null : new User { Nombre = cliente }
    };

    [Fact]
    public async Task DashboardAsync_CalculaTotalesYPorEstado()
    {
        var today = DateTime.UtcNow.Date;
        var orders = new List<Order>
        {
            BuildOrder("PED-001", OrderStatus.Pendiente, 100m, today.AddHours(10)),
            BuildOrder("PED-002", OrderStatus.Entregado, 200m, today.AddHours(9)),
            BuildOrder("PED-003", OrderStatus.Entregado, 50m, today.AddHours(8)),
            BuildOrder("PED-004", OrderStatus.Cancelado, 300m, today.AddHours(7))
        };
        CreateRepository(orders);

        var result = await CreateService().DashboardAsync(CancellationToken.None);

        result.Should().NotBeNull();
        result.TotalPedidos.Should().Be(4);
        result.VentasTotales.Should().Be(650m);
        result.Pendientes.Should().Be(1);
        result.PorEstado.Should().ContainKey("Pendiente").WhoseValue.Should().Be(1);
        result.PorEstado.Should().ContainKey("Entregado").WhoseValue.Should().Be(2);
        result.PorEstado.Should().ContainKey("Cancelado").WhoseValue.Should().Be(1);
    }

    [Fact]
    public async Task DashboardAsync_SalesChart_CubreUltimaSemanaConCerosEnDiasSinVentas()
    {
        var today = DateTime.UtcNow.Date;
        var twoDaysAgo = today.AddDays(-2);
        var orders = new List<Order>
        {
            BuildOrder("PED-001", OrderStatus.Entregado, 100m, twoDaysAgo.AddHours(12)),
            BuildOrder("PED-002", OrderStatus.Entregado, 50m, twoDaysAgo.AddHours(14))
        };
        CreateRepository(orders);

        var result = await CreateService().DashboardAsync(CancellationToken.None);

        result.SalesChart.Should().HaveCount(7);
        result.SalesChart.All(s => DateTime.TryParse(s.Dia, out _)).Should().BeTrue();
        result.SalesChart.Last().Dia.Should().Be(today.ToString("yyyy-MM-dd"));
        result.SalesChart.Single(s => s.Dia == twoDaysAgo.ToString("yyyy-MM-dd")).Ventas.Should().Be(150m);
        result.SalesChart.First().Ventas.Should().Be(0m);
    }

    [Fact]
    public async Task DashboardAsync_RecentOrders_DevuelveTop5MasRecientesConCliente()
    {
        var today = DateTime.UtcNow.Date;
        var orders = Enumerable.Range(0, 7)
            .Select(i => BuildOrder($"PED-{i:000}", OrderStatus.Entregado, 10m + i, today.AddMinutes(-i), $"Cliente {i}"))
            .ToList();
        CreateRepository(orders);

        var result = await CreateService().DashboardAsync(CancellationToken.None);

        result.RecentOrders.Should().HaveCount(5);
        result.RecentOrders.Should().BeInDescendingOrder(r => r.Fecha);
        result.RecentOrders[0].Id.Should().NotBeEmpty();
        result.RecentOrders[0].NumeroPedido.Should().Be("PED-000");
        result.RecentOrders[0].Cliente.Should().Be("Cliente 0");
        result.RecentOrders[0].Estado.Should().Be("Entregado");
        result.RecentOrders[0].Total.Should().Be(10m);
        result.RecentOrders.Should().NotContain(r => r.NumeroPedido == "PED-006");
    }
}