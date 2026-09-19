using Bunit;
using Bunit.TestDoubles;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Layout;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using QuickBite.Shared.Auth;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class LayoutTests : TestContext
{
    private readonly Mock<IAuthService> _authServiceMock;

    public LayoutTests()
    {
        _authServiceMock = new Mock<IAuthService>();
        _authServiceMock.Setup(x => x.CurrentUser).Returns(new UserSummaryDto
        {
            Nombre = "Admin User",
            Email = "admin@quickbite.com",
            Rol = "Admin"
        });

        Services.AddMudServices();
        Services.AddSingleton(_authServiceMock.Object);
        
        JSInterop.Mode = JSRuntimeMode.Loose;
    }

    [Fact]
    public void NavMenu_Renders_NavigationLinks()
    {
        // Act
        var cut = RenderComponent<NavMenu>();

        // Assert
        cut.Markup.Should().Contain("Dashboard");
        cut.Markup.Should().Contain("Productos");
        cut.Markup.Should().Contain("Pedidos");
        cut.Markup.Should().Contain("Repartidores");
        cut.Markup.Should().Contain("Reportes");
        cut.Markup.Should().Contain("Auditoría");
        cut.Markup.Should().Contain("Configuración");
        cut.Markup.Should().Contain("Mi Perfil");
    }

    [Fact]
    public void MainLayout_Renders_HeaderAndDrawer()
    {
        // Act
        var cut = RenderComponent<MainLayout>();

        // Assert
        cut.Markup.Should().Contain("QuickBite Admin");
    }

    [Fact]
    public void NotFound_Renders_404Message()
    {
        // Act
        var cut = RenderComponent<NotFound>();

        // Assert
        cut.Markup.Should().Contain("404");
        cut.Markup.Should().Contain("Página no encontrada");
        cut.Markup.Should().Contain("Volver al Inicio");
    }
}
