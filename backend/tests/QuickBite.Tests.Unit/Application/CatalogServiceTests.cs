using FluentAssertions;
using Moq;
using QuickBite.Application.Catalog;
using QuickBite.Application.Catalog.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;

namespace QuickBite.Tests.Unit.Application;

public class CatalogServiceTests
{
    private readonly Mock<IProductRepository> _products = new();
    private readonly Mock<ICategoryRepository> _categories = new();
    private readonly Mock<IPromotionRepository> _promotions = new();
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IImageService> _imageService = new();

    public CatalogServiceTests()
    {
        _unitOfWork.SetupGet(u => u.Products).Returns(_products.Object);
        _unitOfWork.SetupGet(u => u.Categories).Returns(_categories.Object);
        _unitOfWork.SetupGet(u => u.Promotions).Returns(_promotions.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);
        _products.Setup(p => p.ExistsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync(true);
    }

    private CatalogService CreateService() => new(_unitOfWork.Object, _imageService.Object);

    [Fact]
    public async Task CreateCategoryAsync_ConIcono_GuardaYDevuelveElIcono()
    {
        var result = await CreateService().CreateCategoryAsync(new CreateCategoryRequest
        {
            Nombre = "Donas",
            Descripcion = "Repostería",
            Orden = 2,
            Icon = "🍩"
        });

        result.Icon.Should().Be("🍩");
        _categories.Verify(c => c.AddAsync(It.Is<Category>(cat => cat.Icon == "🍩"), It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateCategoryAsync_ConIcono_ActualizaYDevuelveElIcono()
    {
        var categoryId = Guid.NewGuid();
        var category = new Category { Id = categoryId, Nombre = "Bebidas", Icon = null };
        _categories.Setup(c => c.GetByIdAsync(categoryId, It.IsAny<CancellationToken>())).ReturnsAsync(category);

        var result = await CreateService().UpdateCategoryAsync(categoryId, new UpdateCategoryRequest
        {
            Icon = "🥤"
        });

        category.Icon.Should().Be("🥤");
        result.Icon.Should().Be("🥤");
        _categories.Verify(c => c.Update(category), Times.Once);
    }

    [Fact]
    public async Task GetPriceHistoryAsync_ProductoNoExiste_LanzaNotFound()
    {
        _products.Setup(p => p.ExistsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync(false);

        var act = () => CreateService().GetPriceHistoryAsync(Guid.NewGuid());

        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task DeleteProductAsync_ProductoNoExiste_LanzaNotFound()
    {
        _products.Setup(p => p.ExistsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync(false);

        var act = () => CreateService().DeleteProductAsync(Guid.NewGuid());

        await act.Should().ThrowAsync<NotFoundException>();
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
        _products.Verify(p => p.SoftDeleteAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task DeleteProductAsync_ProductoExiste_EjecutaSoftDelete()
    {
        var productId = Guid.NewGuid();

        await CreateService().DeleteProductAsync(productId);

        _products.Verify(p => p.SoftDeleteAsync(productId, It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task GetPriceHistoryAsync_DevuelveHistorialConNombreDeUsuario()
    {
        var productId = Guid.NewGuid();
        var created = new DateTime(2026, 9, 1, 10, 0, 0, DateTimeKind.Utc);
        _products.Setup(p => p.GetPriceHistoryAsync(productId, It.IsAny<CancellationToken>())).ReturnsAsync(
        [
            new ProductPriceHistory { Id = Guid.NewGuid(), ProductoId = productId, PrecioAnterior = 50m, PrecioNuevo = 60m, Usuario = new User { Nombre = "Admin" }, Motivo = "inflacion", CreadoEn = created }
        ]);

        var history = await CreateService().GetPriceHistoryAsync(productId);

        var item = history.Should().ContainSingle().Subject;
        item.PrecioAnterior.Should().Be(50m);
        item.PrecioNuevo.Should().Be(60m);
        item.Usuario.Should().Be("Admin");
        item.Motivo.Should().Be("inflacion");
        item.CreadoEn.Should().Be(created);
    }

    [Fact]
    public async Task UpdateProductAsync_ConImagenUrl_PersisteImagenSobreEntidadRastreada()
    {
        var productId = Guid.NewGuid();
        var product = new Product
        {
            Id = productId,
            Nombre = "Hamburguesa",
            Precio = 50m,
            ImagenUrl = "https://img.test/vieja.png",
            Disponible = true
        };
        _products.Setup(p => p.GetTrackedByIdAsync(productId, It.IsAny<CancellationToken>())).ReturnsAsync(product);
        _products.Setup(p => p.GetByIdAsync(productId, It.IsAny<CancellationToken>())).ReturnsAsync(product);

        var result = await CreateService().UpdateProductAsync(productId, new UpdateProductRequest
        {
            ImagenUrl = "https://zkueflkfkvrhyqxobrrm.supabase.co/storage/v1/object/public/catalog-images/nueva.png"
        });

        product.ImagenUrl.Should().Be("https://zkueflkfkvrhyqxobrrm.supabase.co/storage/v1/object/public/catalog-images/nueva.png");
        result.ImagenUrl.Should().Be("https://zkueflkfkvrhyqxobrrm.supabase.co/storage/v1/object/public/catalog-images/nueva.png");
        _products.Verify(p => p.GetTrackedByIdAsync(productId, It.IsAny<CancellationToken>()), Times.Once);
        _products.Verify(p => p.Update(It.IsAny<Product>()), Times.Never);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdateProductAsync_SinImagenUrl_ConservaImagenExistente()
    {
        var productId = Guid.NewGuid();
        var product = new Product
        {
            Id = productId,
            Nombre = "Hamburguesa",
            Precio = 50m,
            ImagenUrl = "https://img.test/existente.png",
            Disponible = true
        };
        _products.Setup(p => p.GetTrackedByIdAsync(productId, It.IsAny<CancellationToken>())).ReturnsAsync(product);
        _products.Setup(p => p.GetByIdAsync(productId, It.IsAny<CancellationToken>())).ReturnsAsync(product);

        var result = await CreateService().UpdateProductAsync(productId, new UpdateProductRequest
        {
            Nombre = "Hamburguesa Doble"
        });

        product.ImagenUrl.Should().Be("https://img.test/existente.png");
        result.ImagenUrl.Should().Be("https://img.test/existente.png");
        _products.Verify(p => p.GetTrackedByIdAsync(productId, It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task DeleteCategoryAsync_CategoriaNoExiste_LanzaNotFound()
    {
        _categories.Setup(c => c.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync((Category?)null);

        var act = () => CreateService().DeleteCategoryAsync(Guid.NewGuid());

        await act.Should().ThrowAsync<NotFoundException>();
        _categories.Verify(c => c.Delete(It.IsAny<Category>()), Times.Never);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task DeleteCategoryAsync_CategoriaConProductos_LanzaConflict()
    {
        var categoryId = Guid.NewGuid();
        var category = new Category { Id = categoryId, Nombre = "Con Productos" };
        _categories.Setup(c => c.GetByIdAsync(categoryId, It.IsAny<CancellationToken>())).ReturnsAsync(category);
        _products.Setup(p => p.ExistsByCategoryAsync(categoryId, It.IsAny<CancellationToken>())).ReturnsAsync(true);

        var act = () => CreateService().DeleteCategoryAsync(categoryId);

        await act.Should().ThrowAsync<ConflictException>();
        _categories.Verify(c => c.Delete(It.IsAny<Category>()), Times.Never);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
    }

    [Fact]
    public async Task DeleteCategoryAsync_CategoriaSinProductos_EliminaFisicamente()
    {
        var categoryId = Guid.NewGuid();
        var category = new Category { Id = categoryId, Nombre = "Sin Productos" };
        _categories.Setup(c => c.GetByIdAsync(categoryId, It.IsAny<CancellationToken>())).ReturnsAsync(category);
        _products.Setup(p => p.ExistsByCategoryAsync(categoryId, It.IsAny<CancellationToken>())).ReturnsAsync(false);

        await CreateService().DeleteCategoryAsync(categoryId);

        _categories.Verify(c => c.Delete(category), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CreatePromotionAsync_GuardaYDevuelveLaPromocion()
    {
        var result = await CreateService().CreatePromotionAsync(new CreatePromotionRequest
        {
            Titulo = "2x1 en Tacos",
            Subtitulo = "Solo hoy",
            ColorHex = "#0D9488",
            Orden = 1
        });

        result.Titulo.Should().Be("2x1 en Tacos");
        result.Subtitulo.Should().Be("Solo hoy");
        result.ColorHex.Should().Be("#0D9488");
        _promotions.Verify(p => p.AddAsync(It.Is<Promotion>(pr => pr.Titulo == "2x1 en Tacos"), It.IsAny<CancellationToken>()), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdatePromotionAsync_ActualizaYDevuelveLaPromocion()
    {
        var promoId = Guid.NewGuid();
        var promo = new Promotion { Id = promoId, Titulo = "Viejo", Subtitulo = "Sub", ColorHex = "#000000" };
        _promotions.Setup(p => p.GetByIdAsync(promoId, It.IsAny<CancellationToken>())).ReturnsAsync(promo);

        var result = await CreateService().UpdatePromotionAsync(promoId, new UpdatePromotionRequest
        {
            Titulo = "Nuevo",
            Subtitulo = "Sub nuevo",
            ColorHex = "#FFFFFF"
        });

        promo.Titulo.Should().Be("Nuevo");
        promo.Subtitulo.Should().Be("Sub nuevo");
        promo.ColorHex.Should().Be("#FFFFFF");
        result.Titulo.Should().Be("Nuevo");
        _promotions.Verify(p => p.Update(promo), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task UpdatePromotionAsync_NoExiste_LanzaNotFound()
    {
        _promotions.Setup(p => p.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync((Promotion?)null);

        var act = () => CreateService().UpdatePromotionAsync(Guid.NewGuid(), new UpdatePromotionRequest { Titulo = "X" });

        await act.Should().ThrowAsync<NotFoundException>();
    }

    [Fact]
    public async Task DeletePromotionAsync_EliminaFisicamente()
    {
        var promoId = Guid.NewGuid();
        var promo = new Promotion { Id = promoId, Titulo = "A eliminar" };
        _promotions.Setup(p => p.GetByIdAsync(promoId, It.IsAny<CancellationToken>())).ReturnsAsync(promo);

        await CreateService().DeletePromotionAsync(promoId);

        _promotions.Verify(p => p.Delete(promo), Times.Once);
        _unitOfWork.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task DeletePromotionAsync_NoExiste_LanzaNotFound()
    {
        _promotions.Setup(p => p.GetByIdAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync((Promotion?)null);

        var act = () => CreateService().DeletePromotionAsync(Guid.NewGuid());

        await act.Should().ThrowAsync<NotFoundException>();
        _promotions.Verify(p => p.Delete(It.IsAny<Promotion>()), Times.Never);
    }

    [Fact]
    public async Task GetPromotionsAsync_DevuelveSoloActivas()
    {
        _promotions.Setup(p => p.GetActiveAsync(It.IsAny<CancellationToken>())).ReturnsAsync(
        [
            new Promotion { Id = Guid.NewGuid(), Titulo = "Promo 1", Subtitulo = "Sub 1", ColorHex = "#0D9488", Activa = true },
            new Promotion { Id = Guid.NewGuid(), Titulo = "Promo 2", Subtitulo = "Sub 2", ColorHex = "#2563EB", Activa = true }
        ]);

        var promos = await CreateService().GetPromotionsAsync();

        promos.Should().HaveCount(2);
        promos[0].Titulo.Should().Be("Promo 1");
        promos[1].Titulo.Should().Be("Promo 2");
    }
}