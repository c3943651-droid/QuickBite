using Bunit;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class InventoryPageTests : TestContext
{
    private readonly Mock<IProductService> _productServiceMock;
    private readonly Guid _hamburguesaId = Guid.NewGuid();
    private readonly Guid _pizzaId = Guid.NewGuid();

    public InventoryPageTests()
    {
        _productServiceMock = new Mock<IProductService>();

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_productServiceMock.Object);
    }

    private ProductListItem Hamburguesa => new(_hamburguesaId, "Hamburguesa Clásica", "Carne y queso", 12.50m, null, true, null, Stock: 20, StockMinimo: 5);
    private ProductListItem PizzaBaja => new(_pizzaId, "Pizza Margherita", "Tomate y mozzarella", 15.00m, null, true, null, Stock: 3, StockMinimo: 10);

    private void SetupProducts(params ProductListItem[] items)
    {
        _productServiceMock
            .Setup(x => x.GetProductsAsync(It.IsAny<ProductFilter>(), It.IsAny<CancellationToken>()))
            .Returns(Task.FromResult<PagedResult<ProductListItem>?>(
                new PagedResult<ProductListItem>(new List<ProductListItem>(items), items.Length, 1, 100, 1)));
    }

    private IRenderedComponent<Inventory> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        RenderComponent<MudDialogProvider>();
        return RenderComponent<Inventory>();
    }

    [Fact]
    public void Render_LoadsAndDisplaysStockWithStatusBadges()
    {
        SetupProducts(Hamburguesa, PizzaBaja);

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Hamburguesa Clásica");
            cut.Markup.Should().Contain("Pizza Margherita");
            cut.Markup.Should().Contain("Stock actual");
            cut.Markup.Should().Contain("Stock mínimo");
            cut.Markup.Should().Contain("20");
            cut.Markup.Should().Contain("3");
        });
    }

    [Fact]
    public void Render_ShowsSummaryCards()
    {
        SetupProducts(Hamburguesa, PizzaBaja);

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Total de productos");
            cut.Markup.Should().Contain(">2<");
            cut.Markup.Should().Contain("Productos con stock bajo");
            cut.Markup.Should().Contain(">1<");
        });
    }

    [Fact]
    public void FilterStockBajo_OnlyShowsLowStockProducts()
    {
        SetupProducts(Hamburguesa, PizzaBaja);

        var cut = RenderPage();

        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Pizza Margherita"));
        cut.FindAll("button").First(b => b.TextContent.Contains("Solo stock bajo")).Click();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Pizza Margherita");
            cut.Markup.Should().NotContain("Hamburguesa Clásica");
        });
    }

    [Fact]
    public async Task SearchByNombre_FiltersProducts()
    {
        SetupProducts(Hamburguesa, PizzaBaja);

        var cut = RenderPage();
        cut.WaitForAssertion(() => cut.Markup.Should().Contain("Hamburguesa Clásica"));

        var search = cut.FindComponent<MudTextField<string>>();
        await cut.InvokeAsync(() => search.Instance.ValueChanged.InvokeAsync("pizza"));

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Pizza Margherita");
            cut.Markup.Should().NotContain("Hamburguesa Clásica");
        });
    }

    [Fact]
    public void Render_ServiceReturnsNull_ShowsError()
    {
        _productServiceMock
            .Setup(x => x.GetProductsAsync(It.IsAny<ProductFilter>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((PagedResult<ProductListItem>?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
            cut.Markup.Should().Contain("No se pudieron cargar los productos."));
    }

    [Fact]
    public void Render_NoProducts_ShowsEmptyState()
    {
        SetupProducts();

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
            cut.Markup.Should().Contain("No hay productos que coincidan con los filtros."));
    }
}