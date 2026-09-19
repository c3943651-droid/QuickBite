using Bunit;
using Bunit.TestDoubles;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using QuickBite.Shared.Dashboard;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class DashboardTests : TestContext
{
    private readonly Mock<IDashboardService> _dashboardServiceMock;
    private readonly Mock<ISnackbar> _snackbarMock;

    public DashboardTests()
    {
        _dashboardServiceMock = new Mock<IDashboardService>();
        _snackbarMock = new Mock<ISnackbar>();

        Services.AddMudServices();
        Services.AddSingleton(_dashboardServiceMock.Object);
        Services.AddSingleton(_snackbarMock.Object);

        JSInterop.Mode = JSRuntimeMode.Loose;
    }

    [Fact]
    public void Dashboard_Renders_KPICardsAndHeader()
    {
        // Arrange
        var mockData = new DashboardDataDto
        {
            TotalPedidos = 42,
            VentasTotales = 1250.50m,
            Pendientes = 3,
            PorEstado = new Dictionary<string, int>
            {
                { "Pendiente", 3 },
                { "Entregado", 39 }
            },
            RecentOrders = new List<RecentOrderDto>
            {
                new RecentOrderDto
                {
                    Id = Guid.NewGuid(),
                    NumeroPedido = "ORD-001",
                    Cliente = "Juan Pérez",
                    Estado = "Pendiente",
                    Total = 150.00m,
                    Fecha = DateTime.Now
                }
            }
        };

        _dashboardServiceMock
            .Setup(x => x.GetDashboardAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(mockData);

        // Act
        var cut = RenderComponent<Dashboard>();

        // Assert
        cut.Markup.Should().Contain("Dashboard");
        cut.Markup.Should().Contain("Total Pedidos");
        cut.Markup.Should().Contain("42");
        cut.Markup.Should().Contain("Ventas Totales");
        cut.Markup.Should().Contain("1,250.50");
        cut.Markup.Should().Contain("Pendientes");
        cut.Markup.Should().Contain("ORD-001");
        cut.Markup.Should().Contain("Juan Pérez");
    }
}
