using Bunit;
using FluentAssertions;
using Microsoft.AspNetCore.Components;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Profile;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class ProfilePageTests : TestContext
{
    private readonly Mock<IUserService> _userServiceMock;
    private readonly Mock<IAuthService> _authServiceMock;

    public ProfilePageTests()
    {
        _userServiceMock = new Mock<IUserService>();
        _authServiceMock = new Mock<IAuthService>();

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_userServiceMock.Object);
        Services.AddSingleton(_authServiceMock.Object);
    }

    private static UserProfile Profile() => new()
    {
        Id = Guid.Parse("00000000-0000-0000-0000-000000000001"),
        Nombre = "Carlos Admin",
        Email = "admin@quickbite.com",
        Telefono = "+34 600 000 000",
        Rol = "administrador"
    };

    private static List<SessionInfo> Sessions() => new()
    {
        new SessionInfo
        {
            Id = Guid.Parse("00000000-0000-0000-0000-000000000001"),
            IpOrigen = "10.0.0.1",
            EsActual = true
        },
        new SessionInfo
        {
            Id = Guid.Parse("00000000-0000-0000-0000-000000000002"),
            IpOrigen = "10.0.0.2"
        }
    };

    private void SetupSuccess()
    {
        _userServiceMock.Setup(x => x.GetProfileAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Profile());
        _userServiceMock.Setup(x => x.GetSessionsAsync(It.IsAny<CancellationToken>())).ReturnsAsync(Sessions());
        _userServiceMock.Setup(x => x.UpdateProfileAsync(It.IsAny<string>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Profile());
        _userServiceMock.Setup(x => x.ChangePasswordAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);
    }

    private IRenderedComponent<Profile> RenderPage() => RenderComponent<Profile>();

    [Fact]
    public void Render_DisplaysProfileData()
    {
        SetupSuccess();

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Carlos Admin");
            cut.Markup.Should().Contain("admin@quickbite.com");
            cut.Markup.Should().Contain("2 sesiones activas");
        });
    }

    [Fact]
    public void GuardarPerfil_UpdatesProfile()
    {
        SetupSuccess();

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Carlos Admin"));

        cut.Find(".pf-nombre input").Change("Nuevo Nombre");
        cut.Find(".pf-telefono input").Change("+34 611 111 111");
        cut.Find("button.btn-guardar-perfil").Click();

        cut.WaitForAssertion(() =>
            _userServiceMock.Verify(x => x.UpdateProfileAsync("Nuevo Nombre", "+34 611 111 111", It.IsAny<CancellationToken>()), Times.Once));
    }

    [Fact]
    public void GuardarPerfil_WithoutName_DoesNotCallService()
    {
        SetupSuccess();

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Carlos Admin"));

        cut.Find(".pf-nombre input").Change("");
        cut.Find("button.btn-guardar-perfil").Click();

        cut.WaitForAssertion(() =>
            _userServiceMock.Verify(x => x.UpdateProfileAsync(It.IsAny<string>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()), Times.Never));
    }

    [Fact]
    public void CambiarPassword_WhenMismatch_DoesNotCallService()
    {
        SetupSuccess();

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Carlos Admin"));

        cut.Find(".pw-actual input").Change("actual");
        cut.Find(".pw-nueva input").Change("nueva123");
        cut.Find(".pw-confirm input").Change("distinta");
        cut.Find("button.btn-cambiar-password").Click();

        cut.WaitForAssertion(() =>
            _userServiceMock.Verify(x => x.ChangePasswordAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()), Times.Never));
    }

    [Fact]
    public void CambiarPassword_WhenValid_CallsService()
    {
        SetupSuccess();

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Carlos Admin"));

        cut.Find(".pw-actual input").Change("actual");
        cut.Find(".pw-nueva input").Change("nueva123");
        cut.Find(".pw-confirm input").Change("nueva123");
        cut.Find("button.btn-cambiar-password").Click();

        cut.WaitForAssertion(() =>
            _userServiceMock.Verify(x => x.ChangePasswordAsync("actual", "nueva123", It.IsAny<CancellationToken>()), Times.Once));
    }

    [Fact]
    public void CerrarSesion_LogsOutAndNavigates()
    {
        SetupSuccess();

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Carlos Admin"));

        cut.Find("button.btn-cerrar-sesion").Click();

        cut.WaitForAssertion(() => _authServiceMock.Verify(x => x.LogoutAsync(), Times.Once));
        cut.WaitForAssertion(() => Services.GetRequiredService<NavigationManager>().Uri.Should().EndWith("/login"));
    }

    [Fact]
    public void Render_WhenProfileFails_ShowsError()
    {
        _userServiceMock.Setup(x => x.GetProfileAsync(It.IsAny<CancellationToken>())).ReturnsAsync((UserProfile?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudo cargar tu perfil."));
    }
}