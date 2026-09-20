using Bunit;
using FluentAssertions;
using Microsoft.AspNetCore.Components.Web;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Reports;
using QuickBite.AdminBlazor.Pages.Reports;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class DeliveryPerformancePageTests : TestContext
{
    private readonly Mock<IReportService> _reportServiceMock;
    private readonly Mock<ICsvService> _csvServiceMock;

    public DeliveryPerformancePageTests()
    {
        _reportServiceMock = new Mock<IReportService>();
        _csvServiceMock = new Mock<ICsvService>();

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_reportServiceMock.Object);
        Services.AddSingleton(_csvServiceMock.Object);
    }

    private static List<DeliveryPerformanceRow> Rows() => new()
    {
        new(Guid.Parse("00000000-0000-0000-0000-000000000001"), "Pedro Pérez", 25, 28, 35.5, 1),
        new(Guid.Parse("00000000-0000-0000-0000-000000000002"), "María López", 18, 20, 40.0, 0)
    };

    private IRenderedComponent<DeliveryPerformance> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<DeliveryPerformance>();
    }

    [Fact]
    public void Render_DisplaysChartAndRows()
    {
        _reportServiceMock
            .Setup(x => x.GetDeliveryPerformanceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Rendimiento de repartidores");
            cut.Markup.Should().Contain("Pedro Pérez");
            cut.Markup.Should().Contain("María López");
            cut.Markup.Should().Contain("35.5 min");
            cut.Markup.Should().Contain("Minutos promedio");
            cut.Markup.Should().Contain("Cancelaciones");
        });
    }

    [Fact]
    public void Render_WhenServiceFails_ShowsError()
    {
        _reportServiceMock
            .Setup(x => x.GetDeliveryPerformanceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync((IReadOnlyList<DeliveryPerformanceRow>?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudo cargar el reporte de rendimiento."));
    }

    [Fact]
    public void Render_WhenEmpty_ShowsEmptyState()
    {
        _reportServiceMock
            .Setup(x => x.GetDeliveryPerformanceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<DeliveryPerformanceRow>());

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Sin datos de rendimiento para mostrar."));
    }

    [Fact]
    public async Task RefreshButton_ReloadsData()
    {
        var callCount = 0;
        _reportServiceMock
            .Setup(x => x.GetDeliveryPerformanceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(() =>
            {
                callCount++;
                return Rows();
            });

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Pedro Pérez"));

        await cut.Find("button.refresh-delivery-performance").ClickAsync(new MouseEventArgs());

        cut.WaitForAssertion(() => callCount.Should().BeGreaterThan(1));
    }

    [Fact]
    public void ExportButton_BuildsCsv()
    {
        _reportServiceMock
            .Setup(x => x.GetDeliveryPerformanceAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        List<CsvRow>? captured = null;
        _csvServiceMock
            .Setup(x => x.DownloadAsync(It.IsAny<string>(), It.IsAny<IEnumerable<CsvRow>>(), It.IsAny<CancellationToken>()))
            .Callback<string, IEnumerable<CsvRow>, CancellationToken>((_, rows, _) => captured = rows.ToList())
            .Returns(Task.CompletedTask);

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Pedro Pérez"));
        cut.Find("button.export-delivery-performance").Click();

        cut.WaitForAssertion(() => captured.Should().NotBeNull());
        captured.Should().HaveCount(2);
        captured![0].Fields.Should().Contain("Repartidor", "Pedro Pérez");
        captured[0].Fields.Should().Contain("Minutos promedio", "35.5");
    }
}