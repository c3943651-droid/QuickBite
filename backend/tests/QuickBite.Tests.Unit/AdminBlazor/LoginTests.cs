using Bunit;
using Bunit.TestDoubles;
using FluentAssertions;
using Microsoft.AspNetCore.Components;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using QuickBite.Shared.Auth;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class LoginTests : TestContext
{
    private readonly Mock<IAuthService> _authServiceMock;
    private readonly Mock<ISnackbar> _snackbarMock;

    public LoginTests()
    {
        _authServiceMock = new Mock<IAuthService>();
        _snackbarMock = new Mock<ISnackbar>();

        Services.AddMudServices();
        Services.AddSingleton(_authServiceMock.Object);
        Services.AddSingleton(_snackbarMock.Object);

        JSInterop.Mode = JSRuntimeMode.Loose;
    }

    [Fact]
    public void Login_Renders_FormFieldsAndSubmitButton()
    {
        // Act
        var cut = RenderComponent<Login>();

        // Assert
        cut.Markup.Should().Contain("QuickBite Admin");
        cut.Markup.Should().Contain("Correo Electrónico");
        cut.Markup.Should().Contain("Contraseña");
        cut.Markup.Should().Contain("Iniciar Sesión");
    }

    [Fact]
    public void Login_CallsAuthService_WhenFormIsSubmitted()
    {
        // Arrange
        _authServiceMock
            .Setup(x => x.LoginAsync(It.IsAny<LoginRequest>()))
            .ReturnsAsync(AuthResult.Success());

        var cut = RenderComponent<Login>();
        var navMan = Services.GetRequiredService<NavigationManager>();

        // Act
        var inputs = cut.FindAll("input");
        inputs[0].Change("admin@quickbite.com");
        inputs[1].Change("Password123!");

        var submit = cut.FindAll("button").First(b => b.TextContent.Contains("Iniciar Sesión"));
        submit.Click();

        // Assert
        cut.WaitForAssertion(() => _authServiceMock.Verify(x => x.LoginAsync(It.Is<LoginRequest>(r =>
            r.Email == "admin@quickbite.com" && r.Password == "Password123!")), Times.Once));

        navMan.Uri.Should().EndWith("/");
    }

    [Fact]
    public void Login_DisplaysErrorMessage_WhenLoginFails()
    {
        // Arrange
        _authServiceMock
            .Setup(x => x.LoginAsync(It.IsAny<LoginRequest>()))
            .ReturnsAsync(AuthResult.Failure("Correo electrónico o contraseña incorrectos."));

        var cut = RenderComponent<Login>();

        // Act
        var inputs = cut.FindAll("input");
        inputs[0].Change("admin@quickbite.com");
        inputs[1].Change("WrongPassword");

        var submit = cut.FindAll("button").First(b => b.TextContent.Contains("Iniciar Sesión"));
        submit.Click();

        // Assert
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Credenciales inválidas o sin conexión con el servidor."));
    }
}
