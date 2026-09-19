using Bunit;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Orders;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class OrdersPageTests : TestContext
{
    private readonly Mock<IAdminOrderService> _orderServiceMock;
    private readonly Mock<ICsvService> _csvServiceMock;
    private readonly Guid _orderId = Guid.Parse("00000000-0000-0000-0000-000000000001");
    private readonly Guid _repartidorId = Guid.Parse("00000000-0000-0000-0000-00000000000a");

    public OrdersPageTests()
    {
        _orderServiceMock = new Mock<IAdminOrderService>();
        _csvServiceMock = new Mock<ICsvService>();

        _orderServiceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<DeliveryPersonItem>
            {
                new(_repartidorId, "Juan Pérez", null, "Disponible", null, 3)
            });

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_orderServiceMock.Object);
        Services.AddSingleton(_csvServiceMock.Object);
    }

    private AdminOrderListItem Pedido =>
        new(_orderId, "QB-1001", "María Gómez", "Pendiente", 150.00m, new DateTime(2026, 9, 1, 12, 30, 0), null);

    private void SetupOrders(params AdminOrderListItem[] items)
    {
        _orderServiceMock
            .Setup(x => x.GetOrdersAsync(It.IsAny<OrderListFilter>(), It.IsAny<CancellationToken>()))
            .Returns(Task.FromResult<PagedResult<AdminOrderListItem>?>(
                new PagedResult<AdminOrderListItem>(new List<AdminOrderListItem>(items), items.Length, 1, 10, 1)));
    }

    private IRenderedComponent<Orders> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<Orders>();
    }

    [Fact]
    public void Render_LoadsAndDisplaysOrdersAndDeliveryPersons()
    {
        SetupOrders(Pedido);

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("QB-1001");
            cut.Markup.Should().Contain("María Gómez");
        });
        _orderServiceMock.Verify(x => x.GetDeliveryPersonsAsync(null, It.IsAny<CancellationToken>()));
    }

    [Fact]
    public void EstadoChip_AppliesStateFilterToQuery()
    {
        SetupOrders(Pedido);

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("QB-1001"));

        cut.FindAll("div.mud-chip").Single(c => c.TextContent!.Contains("Confirmado")).Click();

        cut.WaitForAssertion(() =>
            _orderServiceMock.Verify(x => x.GetOrdersAsync(
                It.Is<OrderListFilter>(f => f.Estado == "Confirmado" && f.Search == null && f.RepartidorId == null),
                It.IsAny<CancellationToken>())));
    }

    [Fact]
    public void ExportCsv_GeneratesPedidosCsv()
    {
        SetupOrders(Pedido);

        var cut = RenderPage();

        cut.WaitForElement("button[aria-label*='CSV']").Click();

        cut.WaitForAssertion(() =>
            _csvServiceMock.Verify(x => x.DownloadAsync(
                It.Is<string>(f => f == "pedidos.csv"),
                It.Is<IEnumerable<CsvRow>>(rows => rows.Any(r =>
                    r.Fields.ContainsKey("Número") && r.Fields["Número"] == "QB-1001" &&
                    r.Fields["Total"] == CsvValue.Currency(150.00m))),
                It.IsAny<CancellationToken>())));
    }

    [Fact]
    public void NavigateToDetail_UsesOrderId()
    {
        SetupOrders(Pedido);

        var cut = RenderPage();
        cut.WaitForAssertion(
            () => cut.Markup.Should().Contain($"href=\"/orders/{_orderId}\""));
    }
}