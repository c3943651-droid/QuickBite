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
    private readonly Mock<IUnitOfWork> _unitOfWork = new();
    private readonly Mock<IImageService> _imageService = new();

    public CatalogServiceTests()
    {
        _unitOfWork.SetupGet(u => u.Products).Returns(_products.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);
        _products.Setup(p => p.ExistsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync(true);
    }

    private CatalogService CreateService() => new(_unitOfWork.Object, _imageService.Object);

    [Fact]
    public async Task GetPriceHistoryAsync_ProductoNoExiste_LanzaNotFound()
    {
        _products.Setup(p => p.ExistsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync(false);

        var act = () => CreateService().GetPriceHistoryAsync(Guid.NewGuid());

        await act.Should().ThrowAsync<NotFoundException>();
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
}