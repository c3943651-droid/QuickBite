using FluentAssertions;
using Moq;
using QuickBite.Application.Cart;
using QuickBite.Application.Cart.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;

namespace QuickBite.Tests.Unit.Application;

public class CartServiceAddItemTests
{
    private readonly Mock<IUnitOfWork> _uow = new();
    private readonly Mock<ICartRepository> _carts = new();
    private readonly Mock<IProductRepository> _products = new();

    public CartServiceAddItemTests()
    {
        _uow.SetupGet(u => u.Carts).Returns(_carts.Object);
        _uow.SetupGet(u => u.Products).Returns(_products.Object);
        _uow.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);
    }

    private static Product ProductoDobleCarne() => new()
    {
        Id = Guid.Parse("c0000000-0000-0000-0000-000000000003"),
        Nombre = "Doble Carne",
        Precio = 6.50m,
        Disponible = true
    };

    private void PrepararProductoYCarrito(Product producto, Cart carrito)
    {
        _products.Setup(p => p.GetByIdAsync(producto.Id, It.IsAny<CancellationToken>())).ReturnsAsync(producto);
        _carts.Setup(c => c.GetActiveByUserIdAsync(carrito.UsuarioId, It.IsAny<CancellationToken>())).ReturnsAsync(carrito);
        _carts
            .Setup(c => c.AddItemAsync(It.IsAny<Guid>(), It.IsAny<CartItem>(), It.IsAny<CancellationToken>()))
            .Callback<Guid, CartItem, CancellationToken>((cartId, item, _) =>
            {
                item.CarritoId = cartId;
                carrito.Items.Add(item);
            });
    }

    [Fact]
    public async Task AddItemAsync_CuandoElProductoYaEstaEnElCarrito_AumentaLaCantidadDeLaLineaExistente()
    {
        var userId = Guid.NewGuid();
        var producto = ProductoDobleCarne();
        var carrito = new Cart { Id = Guid.NewGuid(), UsuarioId = userId };
        var existente = new CartItem { Id = Guid.NewGuid(), CarritoId = carrito.Id, ProductoId = producto.Id, Cantidad = 1, Producto = producto };
        carrito.Items.Add(existente);
        PrepararProductoYCarrito(producto, carrito);

        var service = new CartService(_uow.Object);
        var respuesta = await service.AddItemAsync(userId, new AddCartItemRequest
        {
            ProductoId = producto.Id,
            Cantidad = 2
        });

        existente.Cantidad.Should().Be(3);
        carrito.Items.Should().ContainSingle();
        respuesta.Items.Single().Cantidad.Should().Be(3);
        _carts.Verify(
            c => c.AddItemAsync(It.IsAny<Guid>(), It.IsAny<CartItem>(), It.IsAny<CancellationToken>()),
            Times.Never);
        _carts.Verify(
            c => c.UpdateItemAsync(It.IsAny<CartItem>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task AddItemAsync_ConOpcionesDistintas_AgregaUnaLineaNueva()
    {
        var userId = Guid.NewGuid();
        var producto = ProductoDobleCarne();
        var sinCebolla = new ProductOption { Id = Guid.NewGuid(), ProductoId = producto.Id, Nombre = "Sin cebolla", PrecioAdicional = 0.50m, Activo = true };
        producto.Opciones.Add(sinCebolla);
        var carrito = new Cart { Id = Guid.NewGuid(), UsuarioId = userId };
        carrito.Items.Add(new CartItem { Id = Guid.NewGuid(), CarritoId = carrito.Id, ProductoId = producto.Id, Cantidad = 1, Producto = producto });
        PrepararProductoYCarrito(producto, carrito);

        var service = new CartService(_uow.Object);
        await service.AddItemAsync(userId, new AddCartItemRequest
        {
            ProductoId = producto.Id,
            Cantidad = 1,
            OpcionesIds = [sinCebolla.Id]
        });

        carrito.Items.Should().HaveCount(2);
        _carts.Verify(
            c => c.AddItemAsync(carrito.Id, It.IsAny<CartItem>(), It.IsAny<CancellationToken>()),
            Times.Once);
    }
}
