using FluentAssertions;
using Moq;
using QuickBite.Application.Admin;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Tests.Unit.Application;

public class AdminReportsServiceTests
{
    private readonly Mock<IReportRepository> _reports = new();

    private AdminReportsService CreateService() => new(_reports.Object);

    private static List<VentaPorDiaRow> BuildSales()
    {
        var baseDate = new DateTime(2026, 9, 10, 0, 0, 0, DateTimeKind.Utc);
        return
        [
            new VentaPorDiaRow { Dia = baseDate, Ingresos = 300m, Entregados = 10, TotalPedidos = 12 },
            new VentaPorDiaRow { Dia = baseDate.AddDays(1), Ingresos = 500m, Entregados = 20, TotalPedidos = 21 },
            new VentaPorDiaRow { Dia = baseDate.AddDays(2), Ingresos = 150m, Entregados = 5, TotalPedidos = 8 }
        ];
    }

    [Fact]
    public async Task GetSalesByDayAsync_FiltraPorRangoDeFechas()
    {
        _reports.Setup(r => r.GetSalesByDayAsync(It.IsAny<CancellationToken>())).ReturnsAsync(BuildSales());
        var desde = new DateTime(2026, 9, 11, 0, 0, 0, DateTimeKind.Utc);

        var result = await CreateService().GetSalesByDayAsync(desde, new DateTime(2026, 9, 11, 23, 59, 59, DateTimeKind.Utc), CancellationToken.None);

        result.Should().HaveCount(1);
        result[0].Dia.Day.Should().Be(11);
        result[0].Ingresos.Should().Be(500m);
    }

    [Fact]
    public async Task GetSalesByDayAsync_FechaDesdePosteriorAHasta_LanzaValidation()
    {
        var act = () => CreateService().GetSalesByDayAsync(new DateTime(2026, 9, 20), new DateTime(2026, 9, 10));
        await act.Should().ThrowAsync<ValidationException>();
    }

    [Fact]
    public async Task GetTopProductsAsync_ClampaLimiteFueraDeRango()
    {
        _reports.Setup(r => r.GetTopProductsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Enumerable.Range(1, 20).Select(i => new ProductoMasVendidoRow { NombreProducto = $"P{i}" }).ToList());

        var top = await CreateService().GetTopProductsAsync(100, CancellationToken.None);

        top.Should().HaveCount(20);
    }

    [Fact]
    public async Task GetTopClientsAsync_RespetaLimite()
    {
        _reports.Setup(r => r.GetTopClientsAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Enumerable.Range(1, 5).Select(i => new ClienteFrecuenteRow { Nombre = $"C{i}" }).ToList());

        var top = await CreateService().GetTopClientsAsync(3, CancellationToken.None);

        top.Should().HaveCount(3);
    }

    [Fact]
    public async Task GetDeliveryPerformanceAsync_DelegaAlRepositorio()
    {
        _reports.Setup(r => r.GetDeliveryPerformanceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync([new RendimientoRepartidorRow { Nombre = "Pedro", EntregasCompletadas = 5 }]);

        var result = await CreateService().GetDeliveryPerformanceAsync(CancellationToken.None);

        result.Should().ContainSingle().Which.Nombre.Should().Be("Pedro");
    }
}