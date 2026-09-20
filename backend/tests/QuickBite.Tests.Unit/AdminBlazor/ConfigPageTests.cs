using Bunit;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Config;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class ConfigPageTests : TestContext
{
    private readonly Mock<IConfigService> _configServiceMock;

    public ConfigPageTests()
    {
        _configServiceMock = new Mock<IConfigService>();

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_configServiceMock.Object);
    }

    private static ConfigEntry Entry(Guid id, string clave, string valor, bool editable, string? descripcion = null)
        => new() { Id = id, Clave = clave, Valor = valor, Editable = editable, Descripcion = descripcion };

    private static List<ConfigEntry> Entries() => new()
    {
        Entry(Guid.Parse("00000000-0000-0000-0000-000000000001"), "costo_envio_default", "5.00", true, "Costo de envío por defecto"),
        Entry(Guid.Parse("00000000-0000-0000-0000-000000000002"), "tiempo_entrega_estimado", "30", true),
        Entry(Guid.Parse("00000000-0000-0000-0000-000000000003"), "clave_bloqueada", "x", false)
    };

    private IRenderedComponent<Config> RenderPage() => RenderComponent<Config>();

    [Fact]
    public void Render_DisplaysEntries()
    {
        _configServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Entries());

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("costo_envio_default");
            cut.Markup.Should().Contain("Costo de envío por defecto");
            cut.Markup.Should().Contain("Los cambios se aplican en tiempo real al sistema.");
        });
    }

    [Fact]
    public void Render_OnlyEditableRowsShowSaveButton()
    {
        _configServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Entries());

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.FindAll("button.save-config").Should().HaveCount(2));
    }

    [Fact]
    public void Save_PutsEditedValue()
    {
        _configServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Entries());
        _configServiceMock
            .Setup(x => x.UpdateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("costo_envio_default"));

        cut.FindAll(".edi-value input")[0].Change("7.50");
        cut.FindAll("button.save-config")[0].Click();

        cut.WaitForAssertion(() =>
            _configServiceMock.Verify(x => x.UpdateAsync("costo_envio_default", "7.50", It.IsAny<CancellationToken>()), Times.Once));
    }

    [Fact]
    public void Save_WhenServiceFails_KeepsValue()
    {
        _configServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(Entries());
        _configServiceMock
            .Setup(x => x.UpdateAsync(It.IsAny<string>(), It.IsAny<string>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(false);

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("costo_envio_default"));

        cut.FindAll("button.save-config")[0].Click();

        cut.WaitForAssertion(() =>
            _configServiceMock.Verify(x => x.UpdateAsync("costo_envio_default", "5.00", It.IsAny<CancellationToken>()), Times.Once));
    }

    [Fact]
    public void Render_WhenServiceFails_ShowsError()
    {
        _configServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync((IReadOnlyList<ConfigEntry>?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudieron cargar los parámetros de configuración."));
    }

    [Fact]
    public void Render_WhenEmpty_ShowsEmptyState()
    {
        _configServiceMock
            .Setup(x => x.GetAllAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<ConfigEntry>());

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No hay parámetros configurados."));
    }
}