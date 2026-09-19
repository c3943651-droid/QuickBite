using Bunit;
using FluentAssertions;
using Microsoft.AspNetCore.Components;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class DeliveryPersonEditPageTests : TestContext
{
    private readonly Mock<IDeliveryPersonService> _serviceMock = new();

    private static readonly Guid RepartidorId = Guid.Parse("00000000-0000-0000-0000-000000000001");

    public DeliveryPersonEditPageTests()
    {
        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_serviceMock.Object);
    }

    private static AdminDeliveryPerson Repartidor() =>
        new(RepartidorId, "Pedro Pérez", "pedroperez@quickbite.com", "555 123 4567", "disponible", "moto", 7, new DateTime(2026, 1, 15));

    private static PagedResult<AdminDeliveryPerson> PersonPage(params AdminDeliveryPerson[] items) =>
        new(items, items.Length, 1, 100, items.Length == 0 ? 0 : 1);

    private IRenderedComponent<DeliveryPersonEdit> RenderPage(Guid id)
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<DeliveryPersonEdit>(p => p.Add(x => x.Id, id));
    }

    [Fact]
    public void Render_PrefillsVehiculoAndEstado()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(Repartidor()));

        var cut = RenderPage(RepartidorId);

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Editar repartidor");
            cut.Markup.Should().Contain("Pedro Pérez");
        });

        var input = cut.FindComponent<MudTextField<string>>().Find("input");
        input.GetAttribute("value").Should().Be("moto");
    }

    [Fact]
    public void Guardar_SendsUpdateAndNavigatesToDetail()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(Repartidor()));
        _serviceMock
            .Setup(x => x.UpdateAsync(RepartidorId, "bicicleta", "disponible", It.IsAny<CancellationToken>()))
            .ReturnsAsync(OperationResult<AdminDeliveryPerson>.Ok(Repartidor()));

        var cut = RenderPage(RepartidorId);
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Editar repartidor"));

        var input = cut.FindComponent<MudTextField<string>>().Find("input");
        input.Change("bicicleta");

        cut.FindAll("button").Single(b => b.TextContent.Contains("Guardar")).Click();

        cut.WaitForAssertion(() => _serviceMock.Verify(
            x => x.UpdateAsync(RepartidorId, "bicicleta", "disponible", It.IsAny<CancellationToken>()),
            Times.Once));
        Services.GetRequiredService<NavigationManager>().Uri.Should().EndWith($"/delivery-persons/{RepartidorId}");
    }

    [Fact]
    public void Guardar_OnError_ShowsErrorMessage()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(Repartidor()));
        _serviceMock
            .Setup(x => x.UpdateAsync(RepartidorId, It.IsAny<string?>(), It.IsAny<string?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(OperationResult<AdminDeliveryPerson>.Fail("Estado inválido"));

        var cut = RenderPage(RepartidorId);
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Editar repartidor"));

        cut.FindAll("button").Single(b => b.TextContent.Contains("Guardar")).Click();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Estado inválido"));
        cut.Markup.Should().Contain("Editar repartidor");
    }

    [Fact]
    public void Render_WhenRepartidorMissing_ShowsError()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage());

        var cut = RenderPage(RepartidorId);

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("No se pudo cargar el repartidor."));
    }
}