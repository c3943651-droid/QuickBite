using Bunit;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Orders;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class OrderDetailPageTests : TestContext
{
    private readonly Mock<IAdminOrderService> _orderServiceMock;
    private readonly Guid _orderId = Guid.Parse("00000000-0000-0000-0000-000000000001");

    public OrderDetailPageTests()
    {
        _orderServiceMock = new Mock<IAdminOrderService>();
        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_orderServiceMock.Object);
    }

    private static AdminOrderDetail BuildDetail() => new(
        Guid.Parse("00000000-0000-0000-0000-000000000001"),
        "QB-1001",
        "Preparando",
        new DateTime(2026, 9, 1, 12, 30, 0),
        null,
        "María Gómez",
        "maria@mail.com",
        "+52 555 123 4567",
        "Av. Reforma 123, CDMX",
        "Juan Pérez",
        "+52 555 999 0000",
        "Disponible",
        130.00m,
        20.00m,
        150.00m,
        new List<AdminOrderItem>
        {
            new(
                Guid.Parse("00000000-0000-0000-0000-000000000002"),
                "Hamburguesa Clásica",
                80.00m,
                1,
                null,
                80.00m,
                new List<AdminOrderItemOption>
                {
                    new("Queso extra", 10.00m)
                })
        },
        new List<AdminOrderStatusHistory>
        {
            new(
                Guid.Parse("00000000-0000-0000-0000-000000000003"),
                null,
                "Pendiente",
                "Cliente",
                null,
                new DateTime(2026, 9, 1, 12, 30, 0)),
            new(
                Guid.Parse("00000000-0000-0000-0000-000000000004"),
                "Pendiente",
                "Confirmado",
                "Admin",
                "Verificado",
                new DateTime(2026, 9, 1, 12, 35, 0))
        },
        new List<AdminOrderAudit>
        {
            new(
                Guid.Parse("00000000-0000-0000-0000-000000000005"),
                "Cambio de stock",
                "Admin",
                "10.0.0.1",
                new DateTime(2026, 9, 2, 9, 0, 0),
                "{\"stock\":10}")
        });

    private IRenderedComponent<OrderDetail> RenderPage(Guid id)
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<OrderDetail>(p => p.Add(x => x.Id, id));
    }

    [Fact]
    public void Render_DisplaysOrderDetail()
    {
        _orderServiceMock
            .Setup(x => x.GetOrderAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(BuildDetail());

        var cut = RenderPage(_orderId);

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("QB-1001");
            cut.Markup.Should().Contain("Preparando");
            cut.Markup.Should().Contain("María Gómez");
            cut.Markup.Should().Contain("Av. Reforma 123, CDMX");
            cut.Markup.Should().Contain("Hamburguesa Clásica");
            cut.Markup.Should().Contain("Queso extra");
            cut.Markup.Should().Contain("Juan Pérez");
            cut.Markup.Should().Contain("Pedido creado");
        });

        _orderServiceMock.Verify(x => x.GetOrderAsync(_orderId, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public void Render_WhenOrderMissing_ShowsError()
    {
        _orderServiceMock
            .Setup(x => x.GetOrderAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((AdminOrderDetail?)null);

        var cut = RenderPage(_orderId);

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudo cargar el pedido"));
    }
}