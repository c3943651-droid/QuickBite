using Bunit;
using Bunit.TestDoubles;
using FluentAssertions;
using Microsoft.AspNetCore.Components;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class PriceHistoryPageTests : TestContext
{
    private readonly Mock<IProductService> _productServiceMock;
    private readonly Guid _productId = Guid.NewGuid();

    private ProductDetail Product =>
        new(_productId, "Hamburguesa Clásica", "Carne y queso", 12.50m, null, true, null,
            Array.Empty<ProductOption>(), 25);

    private PriceHistoryItem Swap =>
        new(Guid.NewGuid(), 10.00m, 12.50m, "admin@quickbite.com", "Ajuste por inflación", DateTime.UtcNow.AddDays(-3));

    public PriceHistoryPageTests()
    {
        _productServiceMock = new Mock<IProductService>();

        _productServiceMock
            .Setup(x => x.GetProductAsync(_productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Product);

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_productServiceMock.Object);
    }

    private IRenderedComponent<PriceHistory> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<PriceHistory>(parameters => parameters.Add(p => p.Id, _productId));
    }

    [Fact]
    public void Render_LoadsAndDisplaysPriceHistory()
    {
        _productServiceMock
            .Setup(x => x.GetPriceHistoryAsync(_productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<PriceHistoryItem> { Swap });

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Hamburguesa Clásica");
            cut.Markup.Should().Contain("$12.50");
            cut.Markup.Should().Contain("admin@quickbite.com");
            cut.Markup.Should().Contain("Ajuste por inflación");
        });
    }

    [Fact]
    public void Render_WithNoHistory_ShowsEmptyState()
    {
        _productServiceMock
            .Setup(x => x.GetPriceHistoryAsync(_productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((IReadOnlyList<PriceHistoryItem>?)Array.Empty<PriceHistoryItem>());

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
            cut.Markup.Should().Contain("Este producto no ha tenido cambios de precio."));
    }

    [Fact]
    public void Render_ProductNotFound_ShowsError()
    {
        _productServiceMock
            .Setup(x => x.GetProductAsync(_productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((ProductDetail?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
            cut.Markup.Should().Contain("No se encontró el producto."));
    }
}

public class OptionsPageTests : TestContext
{
    private readonly Mock<IProductService> _productServiceMock;
    private readonly Guid _productId = Guid.NewGuid();
    private readonly Guid _optionId = Guid.NewGuid();
    private IRenderedComponent<MudDialogProvider> _dialogProvider = null!;

    private ProductDetail Product =>
        new(_productId, "Hamburguesa Clásica", "Carne y queso", 12.50m, null, true, null,
            new List<ProductOption> { new(_optionId, "Extra queso", 1.00m, true) }, 25);

    public OptionsPageTests()
    {
        _productServiceMock = new Mock<IProductService>();

        _productServiceMock
            .Setup(x => x.GetProductAsync(_productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Product);

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_productServiceMock.Object);
    }

    private IRenderedComponent<Options> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        _dialogProvider = RenderComponent<MudDialogProvider>();
        return RenderComponent<Options>(parameters => parameters.Add(p => p.Id, _productId));
    }

    [Fact]
    public void Render_LoadsAndDisplaysOptions()
    {
        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Hamburguesa Clásica");
            cut.Markup.Should().Contain("Extra queso");
            cut.Markup.Should().Contain("$1.00");
        });
    }

    [Fact]
    public void Delete_ConfirmsAndDeletesOption()
    {
        _productServiceMock
            .Setup(x => x.DeleteOptionAsync(_productId, _optionId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(true);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Extra queso"));
        cut.Find("[aria-label^='Eliminar opción']").Click();

        _dialogProvider.WaitForAssertion(() =>
            _dialogProvider.Markup.Should().Contain("¿Seguro que deseas eliminar"));
        var confirm = _dialogProvider.FindAll("button")
            .First(b => b.TextContent.Contains("Eliminar") && !b.ClassList.Contains("mud-icon-button"));
        confirm.Click();

        _productServiceMock.Verify(x => x.DeleteOptionAsync(
            _productId, _optionId, It.IsAny<CancellationToken>()), Times.Once);
    }
}