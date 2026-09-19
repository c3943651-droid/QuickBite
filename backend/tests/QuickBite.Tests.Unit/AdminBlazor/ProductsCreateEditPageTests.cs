using Bunit;
using Bunit.TestDoubles;
using FluentAssertions;
using Microsoft.AspNetCore.Components;
using Microsoft.Extensions.DependencyInjection;
using Moq;
using MudBlazor;
using MudBlazor.Services;
using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Pages;
using QuickBite.AdminBlazor.Services;
using Xunit;

namespace QuickBite.Tests.Unit.AdminBlazor;

public class ProductsCreatePageTests : TestContext
{
    private readonly Mock<IProductService> _productServiceMock;
    private readonly Mock<ICategoryService> _categoryServiceMock;
    private readonly Mock<ICloudinaryUploadService> _cloudinaryServiceMock;
    private readonly Guid _categoriaComidaId = Guid.NewGuid();
    private IRenderedComponent<MudPopoverProvider> _popover = null!;

    public ProductsCreatePageTests()
    {
        _productServiceMock = new Mock<IProductService>();
        _categoryServiceMock = new Mock<ICategoryService>();
        _cloudinaryServiceMock = new Mock<ICloudinaryUploadService>();

        _categoryServiceMock
            .Setup(x => x.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CategoryItem>
            {
                new(_categoriaComidaId, "Comida Rápida", null, 1, true)
            });

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_productServiceMock.Object);
        Services.AddSingleton(_categoryServiceMock.Object);
        Services.AddSingleton(_cloudinaryServiceMock.Object);
    }

    private IRenderedComponent<Create> RenderPage()
    {
        _popover = RenderComponent<MudPopoverProvider>();
        return RenderComponent<Create>();
    }

    [Fact]
    public void Render_LoadsCategoriesAndShowsForm()
    {
        var cut = RenderPage();

        cut.WaitForAssertion(() =>
            cut.Markup.Should().Contain("Nuevo producto"));

        cut.FindComponents<MudSelect<Guid?>>().Should().ContainSingle();
        var categorySelect = cut.FindComponent<MudSelect<Guid?>>();
        cut.Find(".mud-select-input").Click();

        cut.WaitForAssertion(() =>
            _popover.Markup.Should().Contain("Comida Rápida"));

        categorySelect.Instance.Value.Should().BeNull();
    }

    [Fact]
    public void AddOption_AddsOptionRow()
    {
        var cut = RenderPage();

        cut.FindAll("button").First(b => b.TextContent.Contains("Agregar opción")).Click();

        cut.WaitForAssertion(() =>
            cut.FindAll("[aria-label^='Eliminar opción']").Should().HaveCount(1));
    }

    [Fact]
    public async Task Save_SubmitsProductRequestWithFilledName()
    {
        var productId = Guid.NewGuid();
        var created = new ProductDetail(
            productId, "Hamburguesa", "Desc", 12.50m, null, true, null,
            Array.Empty<ProductOption>(), 0);
        _productServiceMock
            .Setup(x => x.CreateProductAsync(It.IsAny<ProductSaveRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(OperationResult<ProductDetail>.Ok(created));

        var cut = RenderPage();

        var nameField = cut.FindComponent<MudTextField<string>>();
        await cut.InvokeAsync(() => nameField.Instance.ValueChanged.InvokeAsync("Hamburguesa Clásica"));
        cut.Find("form").Submit();

        _productServiceMock.Verify(x => x.CreateProductAsync(
            It.Is<ProductSaveRequest>(r => r.Nombre == "Hamburguesa Clásica"),
            It.IsAny<CancellationToken>()));
        var nav = Services.GetRequiredService<NavigationManager>();
        nav.Uri.Should().EndWith("/products");
    }

    [Fact]
    public async Task Save_WithNamedOption_CreatesOptionForProduct()
    {
        var productId = Guid.NewGuid();
        var created = new ProductDetail(
            productId, "Hamburguesa", null, 10m, null, true, null,
            Array.Empty<ProductOption>(), 0);
        _productServiceMock
            .Setup(x => x.CreateProductAsync(It.IsAny<ProductSaveRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(OperationResult<ProductDetail>.Ok(created));

        var cut = RenderPage();

        var nameField = cut.FindComponent<MudTextField<string>>();
        await cut.InvokeAsync(() => nameField.Instance.ValueChanged.InvokeAsync("Hamburguesa"));
        cut.FindAll("button").First(b => b.TextContent.Contains("Agregar opción")).Click();

        var optionName = cut.FindComponents<MudTextField<string>>()
            .First(f => f.Instance.Label == "Nombre de la opción");
        await cut.InvokeAsync(() => optionName.Instance.ValueChanged.InvokeAsync("Con queso"));

        cut.Find("form").Submit();

        _productServiceMock.Verify(x => x.CreateOptionAsync(
            productId,
            It.Is<OptionSaveRequest>(r => r.Nombre == "Con queso"),
            It.IsAny<CancellationToken>()));
    }
}

public class ProductsEditPageTests : TestContext
{
    private readonly Mock<IProductService> _productServiceMock;
    private readonly Mock<ICategoryService> _categoryServiceMock;
    private readonly Mock<ICloudinaryUploadService> _cloudinaryServiceMock;
    private readonly Guid _productId = Guid.NewGuid();
    private readonly Guid _optionId = Guid.NewGuid();

    private ProductDetail Product =>
        new(_productId, "Hamburguesa Clásica", "Carne y queso", 12.50m, "https://img.test/1.png", true,
            null,
            new List<ProductOption> { new(_optionId, "Extra queso", 1.00m, true) },
            25);

    public ProductsEditPageTests()
    {
        _productServiceMock = new Mock<IProductService>();
        _categoryServiceMock = new Mock<ICategoryService>();
        _cloudinaryServiceMock = new Mock<ICloudinaryUploadService>();

        _categoryServiceMock
            .Setup(x => x.GetCategoriesAsync(It.IsAny<CancellationToken>()))
            .ReturnsAsync(new List<CategoryItem>
            {
                new(Guid.NewGuid(), "Comida Rápida", null, 1, true)
            });

        JSInterop.Mode = JSRuntimeMode.Loose;
        Services.AddMudServices();
        Services.AddSingleton(_productServiceMock.Object);
        Services.AddSingleton(_categoryServiceMock.Object);
        Services.AddSingleton(_cloudinaryServiceMock.Object);
    }

    private IRenderedComponent<Edit> RenderPage()
    {
        RenderComponent<MudPopoverProvider>();
        return RenderComponent<Edit>(parameters => parameters.Add(p => p.Id, _productId));
    }

    private void SetupProduct()
    {
        _productServiceMock
            .Setup(x => x.GetProductAsync(_productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(Product);
    }

    [Fact]
    public void Render_LoadsAndDisplaysProductData()
    {
        SetupProduct();

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
        {
            cut.Markup.Should().Contain("Hamburguesa Clásica");
            cut.Markup.Should().Contain("Extra queso");
        });
        var readOnlyStock = cut.FindComponent<MudNumericField<int?>>().Instance.Value;
        readOnlyStock.Should().Be(25);
    }

    [Fact]
    public void Render_ProductNotFound_ShowsEmptyState()
    {
        _productServiceMock
            .Setup(x => x.GetProductAsync(_productId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((ProductDetail?)null);

        var cut = RenderPage();

        cut.WaitForAssertion(() =>
            cut.Markup.Should().Contain("No se encontró el producto."));
    }

    [Fact]
    public async Task Save_SubmitsUpdatedRequestWithEditedName()
    {
        SetupProduct();
        _productServiceMock
            .Setup(x => x.UpdateProductAsync(It.IsAny<Guid>(), It.IsAny<ProductSaveRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(OperationResult<ProductDetail>.Ok(Product));
        _productServiceMock
            .Setup(x => x.UpdateOptionAsync(It.IsAny<Guid>(), It.IsAny<Guid>(), It.IsAny<OptionSaveRequest>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(OperationResult<ProductOption>.Ok(new ProductOption(_optionId, "Extra queso", 1.00m, true)));

        var cut = RenderPage();

        var nameField = cut.FindComponent<MudTextField<string>>();
        await cut.InvokeAsync(() => nameField.Instance.ValueChanged.InvokeAsync("Hamburguesa Doble"));
        cut.Find("form").Submit();

        _productServiceMock.Verify(x => x.UpdateProductAsync(
            _productId,
            It.Is<ProductSaveRequest>(r => r.Nombre == "Hamburguesa Doble"),
            It.IsAny<CancellationToken>()));
        _productServiceMock.Verify(x => x.UpdateOptionAsync(
            _productId, _optionId,
            It.Is<OptionSaveRequest>(r => r.Nombre == "Extra queso"),
            It.IsAny<CancellationToken>()));
    }
}