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

public class TopClientsPageTests : TestContext
{
    private readonly Mock<IReportService> _reportServiceMock;
    private readonly Mock<ICsvService> _csvServiceMock;

    public TopClientsPageTests()
    {
        _reportServiceMock = new Mock<IReportService>();
        _csvServiceMock = new Mock<ICsvService>();

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_reportServiceMock.Object);
        Services.AddSingleton(_csvServiceMock.Object);
    }

    private static List<TopClientRow> Rows() => new()
    {
        new(Guid.Parse("00000000-0000-0000-0000-00000000000a"), "Ana García", "ana@quickbite.com", 6, 180.00m, 30.00m, new DateTime(2026, 9, 15, 19, 30, 0)),
        new(Guid.Parse("00000000-0000-0000-0000-00000000000b"), "Luis Ramírez", "luis@quickbite.com", 4, 120.00m, 30.00m, null)
    };

    private IRenderedComponent<TopClients> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<TopClients>();
    }

    [Fact]
    public void Render_DisplaysRows()
    {
        _reportServiceMock
            .Setup(x => x.GetTopClientsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Clientes frecuentes");
            cut.Markup.Should().Contain("Ana García");
            cut.Markup.Should().Contain("ana@quickbite.com");
            cut.Markup.Should().Contain("2026-09-15 19:30");
            cut.Markup.Should().Contain("Gasto promedio");
            cut.Markup.Should().Contain("Último pedido");
        });
    }

    [Fact]
    public void Render_LimitSelectShowsSelectedValue()
    {
        _reportServiceMock
            .Setup(x => x.GetTopClientsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
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
            .Setup(x => x.GetTopClientsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((IReadOnlyList<TopClientRow>?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudo cargar el reporte de clientes."));
    }

    [Fact]
    public void Render_WhenEmpty_ShowsEmptyState()
    {
        _reportServiceMock
            .Setup(x => x.GetTopClientsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<TopClientRow>());

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Sin datos para el ranking."));
    }

    [Fact]
    public async Task RefreshButton_ReloadsData()
    {
        var callCount = 0;
        _reportServiceMock
            .Setup(x => x.GetTopClientsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(() =>
            {
                callCount++;
                return Rows();
            });

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Ana García"));

        await cut.Find("button.refresh-top-clients").ClickAsync(new MouseEventArgs());

        cut.WaitForAssertion(() => callCount.Should().BeGreaterThan(1));
    }

    [Fact]
    public void ExportButton_BuildsCsv()
    {
        _reportServiceMock
            .Setup(x => x.GetTopClientsAsync(It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Rows());

        List<CsvRow>? captured = null;
        _csvServiceMock
            .Setup(x => x.DownloadAsync(It.IsAny<string>(), It.IsAny<IEnumerable<CsvRow>>(), It.IsAny<CancellationToken>()))
            .Callback<string, IEnumerable<CsvRow>, CancellationToken>((_, rows, _) => captured = rows.ToList())
            .Returns(Task.CompletedTask);

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Ana García"));
        cut.Find("button.export-top-clients").Click();

        cut.WaitForAssertion(() => captured.Should().NotBeNull());
        captured.Should().HaveCount(2);
        captured![0].Fields.Should().Contain("Cliente", "Ana García");
        captured[0].Fields.Should().Contain("Gasto total", "180.00");
    }
}