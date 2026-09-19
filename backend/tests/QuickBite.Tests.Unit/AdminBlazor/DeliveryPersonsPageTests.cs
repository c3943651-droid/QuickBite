using Bunit;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Components;
using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class DeliveryPersonsPageTests : TestContext
{
    private readonly Mock<IDeliveryPersonService> _serviceMock = new();
    private readonly Mock<IDialogService> _dialogServiceMock = new();

    private static readonly Guid PedroId = Guid.Parse("00000000-0000-0000-0000-000000000001");
    private static readonly Guid AnaId = Guid.Parse("00000000-0000-0000-0000-000000000002");

    public DeliveryPersonsPageTests()
    {
        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_serviceMock.Object);
        Services.AddSingleton(_dialogServiceMock.Object);
    }

    private static AdminDeliveryPerson Person(Guid id, string nombre, string estado, int entregas = 0) =>
        new(id, nombre, $"{nombre.Replace(" ", "").Replace("í", "i")}@quickbite.com", "555 123 4567", estado, "moto", entregas, new DateTime(2026, 1, 15));

    private static PagedResult<AdminDeliveryPerson> PersonPage(params AdminDeliveryPerson[] items) =>
        new(items, items.Length, 1, 100, items.Length == 0 ? 0 : 1);

    private static IDialogReference OkReference()
    {
        var mock = new Mock<IDialogReference>();
        mock.Setup(x => x.Result).Returns(Task.FromResult<DialogResult?>(DialogResult.Ok(true)));
        return mock.Object;
    }

    private IRenderedComponent<DeliveryPersons> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<DeliveryPersons>();
    }

    [Fact]
    public void Render_DisplaysDeliveryPersonsTable()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(
                Person(PedroId, "Pedro Pérez", "disponible", entregas: 12),
                Person(AnaId, "Ana García", "inactivo")));

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Pedro Pérez");
            cut.Markup.Should().Contain("Ana García");
            cut.Markup.Should().Contain("Disponible");
            cut.Markup.Should().Contain("Inactivo");
            cut.Markup.Should().Contain("12");
        });

        _serviceMock.Verify(x => x.GetDeliveryPersonsAsync(null, 1, 100, It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public void Render_WhenServiceFails_ShowsError()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((PagedResult<AdminDeliveryPerson>?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudieron cargar los repartidores."));
    }

    [Fact]
    public void Click_EstadoChip_ReloadWithFilter()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(Person(PedroId, "Pedro Pérez", "disponible")));

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.FindAll(".mud-chip").Count.Should().BeGreaterThanOrEqualTo(4));

        var chipDisponible = cut.FindAll(".mud-chip").First(c => c.TextContent.Trim() == "Disponible");
        chipDisponible.Click();

        cut.WaitForAssertion(() => _serviceMock.Verify(x => x.GetDeliveryPersonsAsync("disponible", 1, 100, It.IsAny<CancellationToken>()), Times.AtLeastOnce));
    }

    [Fact]
    public void Search_FiltersRowsByName()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(
                Person(PedroId, "Pedro Pérez", "disponible"),
                Person(AnaId, "Ana García", "disponible")));

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Pedro Pérez"));

        var input = cut.FindComponent<MudTextField<string>>().Find("input");
        input.Change("Pedro");

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Pedro Pérez"));
        cut.Markup.Should().NotContain("Ana García");
    }

    [Fact]
    public void Click_Desactivar_ConfirmsAndDeactivates()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(Person(PedroId, "Pedro Pérez", "disponible")));
        _serviceMock
            .Setup(x => x.DeactivateAsync(PedroId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(OperationResult<AdminDeliveryPerson>.Ok(Person(PedroId, "Pedro Pérez", "inactivo")));
        _dialogServiceMock
            .Setup(x => x.ShowAsync<ConfirmDialog>(It.IsAny<string>(), It.IsAny<DialogParameters>(), It.IsAny<DialogOptions>()))
            .ReturnsAsync(OkReference());

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.FindAll("button[title=\"Desactivar\"]").Should().HaveCount(1));

        cut.Find("button[title=\"Desactivar\"]").Click();

        cut.WaitForAssertion(() => _serviceMock.Verify(x => x.DeactivateAsync(PedroId, It.IsAny<CancellationToken>()), Times.Once));
    }

    [Fact]
    public void Click_Desactivar_WhenInactivo_IsDisabled()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(Person(PedroId, "Pedro Pérez", "inactivo")));

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
            cut.Find("button[title=\"Desactivar\"]").HasAttribute("disabled").Should().BeTrue());
    }

    [Fact]
    public void Click_NuevoRepartidor_ReloadsAfterDialog()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage());
        _dialogServiceMock
            .Setup(x => x.ShowAsync<NewDeliveryPersonDialog>(It.IsAny<string>(), It.IsAny<DialogOptions>()))
            .ReturnsAsync(OkReference());

        var cut = RenderPage();
        cut.WaitForAssertion(() =>
            cut.FindAll("button").Single(b => b.TextContent.Contains("Nuevo repartidor")).Should().NotBeNull());

        cut.FindAll("button").Single(b => b.TextContent.Contains("Nuevo repartidor")).Click();

        cut.WaitForAssertion(() => _serviceMock.Verify(
            x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()),
            Times.Exactly(2)));
    }
}