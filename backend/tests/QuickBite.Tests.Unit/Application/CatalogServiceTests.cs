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

    public CatalogServiceTests()
    {
        _unitOfWork.SetupGet(u => u.Products).Returns(_products.Object);
        _unitOfWork.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);
        _products.Setup(p => p.ExistsAsync(It.IsAny<Guid>(), It.IsAny<CancellationToken>())).ReturnsAsync(true);
    }

    private CatalogService CreateService() => new(_unitOfWork.Object);

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
}