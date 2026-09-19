using Bunit;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Delivery;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class DeliveryPersonDetailPageTests : TestContext
{
    private readonly Mock<IDeliveryPersonService> _serviceMock = new();

    private static readonly Guid RepartidorId = Guid.Parse("00000000-0000-0000-0000-000000000001");

    public DeliveryPersonDetailPageTests()
    {
        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_serviceMock.Object);
    }

    private static AdminDeliveryPerson Repartidor() =>
        new(RepartidorId, "Pedro Pérez", "pedroperez@quickbite.com", "555 123 4567", "disponible", "moto", 7, new DateTime(2026, 1, 15));

    private static PagedResult<AdminDeliveryPerson> PersonPage(params AdminDeliveryPerson[] items) =>
        new(items, items.Length, 1, 100, items.Length == 0 ? 0 : 1);

    private IRenderedComponent<DeliveryPersonDetail> RenderPage(Guid id)
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<DeliveryPersonDetail>(p => p.Add(x => x.Id, id));
    }

    [Fact]
    public void Render_DisplaysDetailAndMetrics()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(Repartidor()));

        var ahora = DateTime.UtcNow;
        var historial = new List<AdminDeliveryHistoryItem>
        {
            new("QB-2001", "Ana García", 45.00m, ahora.AddDays(-2), 25),
            new("QB-2002", "Luis Ramírez", 60.00m, ahora.AddMonths(-1).AddDays(-2), 35)
        };
        _serviceMock
            .Setup(x => x.GetHistoryAsync(RepartidorId, 1, 100, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PagedResult<AdminDeliveryHistoryItem>(historial, historial.Count, 1, 100, 1));

        var cut = RenderPage(RepartidorId);

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Pedro Pérez");
            cut.Markup.Should().Contain("Datos personales");
            cut.Markup.Should().Contain("Historial de entregas");
            cut.Markup.Should().Contain("QB-2001");
            cut.Markup.Should().Contain("Ana García");
            cut.Markup.Should().Contain("30 min");
        });
    }

    [Fact]
    public void Render_AggregatesMonthlyDeliveries()
    {
        _serviceMock
            .Setup(x => x.GetDeliveryPersonsAsync(It.IsAny<string?>(), It.IsAny<int>(), It.IsAny<int>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(PersonPage(Repartidor()));

        var ahora = DateTime.UtcNow;
        var historial = new List<AdminDeliveryHistoryItem>
        {
            new("QB-2001", "Ana García", 45.00m, ahora.AddDays(-1), 25),
            new("QB-2002", "Luis Ramírez", 60.00m, ahora.AddDays(-3), 35)
        };
        _serviceMock
            .Setup(x => x.GetHistoryAsync(RepartidorId, 1, 100, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new PagedResult<AdminDeliveryHistoryItem>(historial, historial.Count, 1, 100, 1));

        var cut = RenderPage(RepartidorId);

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Entregas del mes");
            cut.Markup.Should().Contain("30 min");
        });
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