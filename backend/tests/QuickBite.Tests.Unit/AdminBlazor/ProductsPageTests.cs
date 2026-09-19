using Bunit;
using Bunit.TestDoubles;
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

public class ProductsPageTests : TestContext
{
    private readonly Mock<IProductService> _productServiceMock;
    private readonly Mock<ICategoryService> _categoryServiceMock;
    private readonly Mock<ICsvService> _csvServiceMock;
    private readonly Guid _hamburguesaId = Guid.NewGuid();
    private readonly Guid _pizzaId = Guid.NewGuid();
    private readonly Guid _categoriaComidaId = Guid.NewGuid();

    private ProductListItem Hamburguesa =>
        new(_hamburguesaId, "Hamburguesa Clásica", "Carne, queso y lechuga", 12.50m, null, true, new CategoryItem(_categoriaComidaId, "Comida Rápida", null, 1, true));

    private ProductListItem Pizza =>
        new(_pizzaId, "Pizza Margherita", "Tomate y mozzarella", 15.00m, null, false, new CategoryItem(_categoriaComidaId, "Comida Rápida", null, 1, true));

    public ProductsPageTests()
    {
        _productServiceMock = new Mock<IProductService>();
        _categoryServiceMock = new Mock<ICategoryService>();
        _csvServiceMock = new Mock<ICsvService>();

        _categoryServiceMock
            .Setup(x => x.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CategoryItem>
            {
                new(_categoriaComidaId, "Comida Rápida", null, 1, true),
                new(Guid.NewGuid(), "Bebidas", null, 2, true)
            });

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_productServiceMock.Object);
        Services.AddSingleton(_categoryServiceMock.Object);
        Services.AddSingleton(_csvServiceMock.Object);
    }

    private void SetupProducts(params ProductListItem[] items)
    {
        _productServiceMock
            .Setup(x => x.GetProductsAsync(It.IsAny<ProductFilter>(), It.IsAny<CancellationToken>()))
            .Returns(Task.FromResult<PagedResult<ProductListItem>?>(
                new PagedResult<ProductListItem>(new List<ProductListItem>(items), items.Length, 1, 10, 1)));
    }

    private IRenderedComponent<Products> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<Products>();
    }

    [Fact]
    public void Render_LoadsAndDisplaysProductsFromServer()
    {
        SetupProducts(Hamburguesa, Pizza);

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Hamburguesa Clásica");
            cut.Markup.Should().Contain("Pizza Margherita");
        });
    }

    [Fact]
    public async Task Search_AppliesTextFilterToQuery()
    {
        SetupProducts(Hamburguesa);

        var cut = RenderPage();

        var search = cut.FindComponent<MudTextField<string>>();
        await cut.InvokeAsync(() => search.Instance.ValueChanged.InvokeAsync("hamburguesa"));

        _productServiceMock.Verify(x => x.GetProductsAsync(
            It.Is<ProductFilter>(f => f.Search == "hamburguesa"),
            It.IsAny<CancellationToken>()));
    }

    [Fact]
    public void ExportCsv_GeneratesCsvWithProducts()
    {
        SetupProducts(Hamburguesa, Pizza);

        var cut = RenderPage();

        var exportButton = cut.WaitForElement("button[aria-label*='CSV']");
        exportButton.Click();

        _csvServiceMock.Verify(x => x.DownloadAsync(
            It.Is<string>(f => f == "productos.csv"),
            It.Is<IEnumerable<CsvRow>>(rows => rows.Any(r =>
                r.Fields.ContainsKey("Nombre") && r.Fields["Nombre"] == "Hamburguesa Clásica")),
            It.IsAny<CancellationToken>()));
    }
}