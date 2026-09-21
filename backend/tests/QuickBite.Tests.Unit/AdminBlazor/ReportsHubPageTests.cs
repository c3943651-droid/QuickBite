using Bunit;
using FluentAssertions;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Pages.Reports;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class ReportsHubPageTests : TestContext
{
    public ReportsHubPageTests()
    {
        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
    }

    [Fact]
    public void Render_ShowsAllReportSections()
    {
        var cut = RenderComponent<Reports>();

        cut.Markup.Should().Contain("Reportes");
        cut.Markup.Should().Contain("Ventas por día");
        cut.Markup.Should().Contain("Productos más vendidos");
        cut.Markup.Should().Contain("Clientes frecuentes");
        cut.Markup.Should().Contain("Rendimiento de repartidores");
    }

    [Fact]
    public void Render_LinksToEachSubReport()
    {
        var cut = RenderComponent<Reports>();

        cut.Markup.Should().Contain("href=\"/reports/sales-by-day\"");
        cut.Markup.Should().Contain("href=\"/reports/top-products\"");
        cut.Markup.Should().Contain("href=\"/reports/top-clients\"");
        cut.Markup.Should().Contain("href=\"/reports/delivery-performance\"");
    }
}