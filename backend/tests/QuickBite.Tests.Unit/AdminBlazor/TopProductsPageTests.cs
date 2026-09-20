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

public class TopProductsPageTests : TestContext
{
    private readonly Mock<IReportService> _reportServiceMock;
    private readonly Mock<ICsvService> _csvServiceMock;

    public TopProductsPageTests()
    {
        _reportServiceMock = new Mock<IReportService>();
        _csvServiceMock = new Mock<ICsvService>();

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_reportServiceMock.Object);
        Services.AddSingleton(_csvServiceMock.Object);
    }

    private static List<TopProductRow> Rows() => new()
    {
        new(Guid.Parse("00000000-0000-0000-0000-000000000001"), "Hamburguesa Clásica", 34, 510.00m, 28),
        new(Guid.Parse("00000000-0000-0000-0000-000000000002"), "Papas Fritas", 41, 205.00m, 30)
    };

    private IRenderedComponent<TopProducts> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<TopProducts>();
    }

    [Fact]
    public void Render_DisplaysChartAndRows()
    {
        _reportServiceMock
            .Setup(x => x.GetTopProductsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Productos más vendidos");
            cut.Markup.Should().Contain("Hamburguesa Clásica");
            cut.Markup.Should().Contain("Papas Fritas");
            cut.Markup.Should().Contain("Unidades vendidas");
            cut.Markup.Should().Contain("Ingresos generados");
        });
    }

    [Fact]
    public void Render_LimitSelectShowsSelectedValue()
    {
        _reportServiceMock
            .Setup(x => x.GetTopProductsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Límite");
            cut.Markup.Should().Contain(">10<");
        });
    }

    [Fact]
    public void ReportLimits_Offers10_20_50()
    {
        ReportLimits.Available.Should().BeEquivalentTo(new[] { 10, 20, 50 });
    }

    [Fact]
    public void Render_WhenServiceFails_ShowsError()
    {
        _reportServiceMock
            .Setup(x => x.GetTopProductsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((IReadOnlyList<TopProductRow>?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudo cargar el reporte de productos."));
    }

    [Fact]
    public async Task RefreshButton_ReloadsData()
    {
        var callCount = 0;
        _reportServiceMock
            .Setup(x => x.GetTopProductsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(() =>
            {
                callCount++;
                return Rows();
            });

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Hamburguesa Clásica"));

        await cut.Find("button.refresh-top-products").ClickAsync(new MouseEventArgs());

        cut.WaitForAssertion(() => callCount.Should().BeGreaterThan(1));
    }

    [Fact]
    public void ExportButton_BuildsCsv()
    {
        _reportServiceMock
            .Setup(x => x.GetTopProductsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        List<CsvRow>? captured = null;
        _csvServiceMock
            .Setup(x => x.DownloadAsync(It.IsAny<string>(), It.IsAny<IEnumerable<CsvRow>>(), It.IsAny<CancellationToken>()))
            .Callback<string, IEnumerable<CsvRow>, CancellationToken>((_, rows, _) => captured = rows.ToList())
            .Returns(Task.CompletedTask);

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Hamburguesa Clásica"));
        cut.Find("button.export-top-products").Click();

        cut.WaitForAssertion(() => captured.Should().NotBeNull());
        captured.Should().HaveCount(2);
        captured![0].Fields.Should().Contain("Producto", "Hamburguesa Clásica");
        captured[0].Fields.Should().Contain("Ingresos generados", "510.00");
    }
}