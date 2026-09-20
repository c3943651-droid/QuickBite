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

public class SalesByDayPageTests : TestContext
{
    private readonly Mock<IReportService> _reportServiceMock;
    private readonly Mock<ICsvService> _csvServiceMock;

    public SalesByDayPageTests()
    {
        _reportServiceMock = new Mock<IReportService>();
        _csvServiceMock = new Mock<ICsvService>();

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_reportServiceMock.Object);
        Services.AddSingleton(_csvServiceMock.Object);
    }

    private static List<SalesByDayRow> Rows() => new()
    {
        new(new DateTime(2026, 9, 10), 12, 9, 2, 1, 245.50m, 20.46m),
        new(new DateTime(2026, 9, 11), 15, 12, 1, 2, 320.00m, 21.33m)
    };

    private IRenderedComponent<SalesByDay> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<SalesByDay>();
    }

    [Fact]
    public void Render_DisplaysChartAndRows()
    {
        _reportServiceMock
            .Setup(x => x.GetSalesByDayAsync(It.IsAny<DateTime?>(), It.IsAny<DateTime?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Ventas por día");
            cut.Markup.Should().Contain("10/09");
            cut.Markup.Should().Contain("2026-09-10");
            cut.Markup.Should().Contain("2026-09-11");
            cut.Markup.Should().Contain("Ticket promedio");
            cut.Markup.Should().Contain("Total pedidos");
        });
    }

    [Fact]
    public void Render_WhenEmpty_ShowsEmptyState()
    {
        _reportServiceMock
            .Setup(x => x.GetSalesByDayAsync(It.IsAny<DateTime?>(), It.IsAny<DateTime?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<SalesByDayRow>());

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Sin datos en el rango seleccionado."));
    }

    [Fact]
    public void Render_WhenServiceFails_ShowsError()
    {
        _reportServiceMock
            .Setup(x => x.GetSalesByDayAsync(It.IsAny<DateTime?>(), It.IsAny<DateTime?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((IReadOnlyList<SalesByDayRow>?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudo cargar el reporte de ventas."));
    }

    [Fact]
    public async Task RefreshButton_ReloadsData()
    {
        var callCount = 0;
        _reportServiceMock
            .Setup(x => x.GetSalesByDayAsync(It.IsAny<DateTime?>(), It.IsAny<DateTime?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(() =>
            {
                callCount++;
                return Rows();
            });

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("2026-09-10"));

        await cut.Find("button.refresh-sales").ClickAsync(new MouseEventArgs());

        cut.WaitForAssertion(() => callCount.Should().BeGreaterThan(1));
    }

    [Fact]
    public void ExportButton_BuildsCsv()
    {
        _reportServiceMock
            .Setup(x => x.GetSalesByDayAsync(It.IsAny<DateTime?>(), It.IsAny<DateTime?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        List<CsvRow>? captured = null;
        _csvServiceMock
            .Setup(x => x.DownloadAsync(It.IsAny<string>(), It.IsAny<IEnumerable<CsvRow>>(), It.IsAny<CancellationToken>()))
            .Callback<string, IEnumerable<CsvRow>, CancellationToken>((_, rows, _) => captured = rows.ToList())
            .Returns(Task.CompletedTask);

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("2026-09-10"));
        cut.Find("button.export-sales").Click(); // Exportar CSV
        cut.WaitForAssertion(() => captured.Should().NotBeNull());

        captured.Should().HaveCount(2);
        captured![0].Fields.Should().Contain("Día", "2026-09-10");
        captured[0].Fields.Should().Contain("Ingresos", "245.50");
    }
}