using FluentAssertions;
using Moq;
using QuickBite.Application.Orders;
using QuickBite.Application.Orders.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;

namespace QuickBite.Tests.Unit.Application;

public class OrderServiceCreateTests
{
    private readonly Mock<IUnitOfWork> _uow = new();
    private readonly Mock<IOrderRepository> _orders = new();
    private readonly Mock<ICartRepository> _carts = new();
    private readonly Mock<IAddressRepository> _addresses = new();

    public OrderServiceCreateTests()
    {
        _uow.SetupGet(u => u.Orders).Returns(_orders.Object);
        _uow.SetupGet(u => u.Carts).Returns(_carts.Object);
        _uow.SetupGet(u => u.Addresses).Returns(_addresses.Object);
        _uow.Setup(u => u.SaveChangesAsync(It.IsAny<CancellationToken>())).ReturnsAsync(true);
    }

    private Order? _pedidoGuardado;

    private void CapturarPedido()
    {
        _pedidoGuardado = null;
        _orders
            .Setup(o => o.AddAsync(It.IsAny<Order>(), It.IsAny<CancellationToken>()))
            .Callback<Order, CancellationToken>((order, _) => _pedidoGuardado = order);
    }

    private static Product ProductoDobleCarne() => new()
    {
        Id = Guid.Parse("c0000000-0000-0000-0000-000000000003"),
        Nombre = "Doble Carne",
        Precio = 6.50m,
        Disponible = true
    };

    private static CartItem LineaDeCarrito(Product producto, short cantidad) => new()
    {
        Id = Guid.NewGuid(),
        ProductoId = producto.Id,
        Cantidad = cantidad,
        Producto = producto
    };

    private void DevolverCarrito(Guid userId, Cart cart) =>
        _carts.Setup(c => c.GetActiveByUserIdAsync(userId, It.IsAny<CancellationToken>())).ReturnsAsync(cart);

    [Fact]
    public async Task CreateAsync_ConElMismoProductoEnDosLineas_GeneraUnaUnicaLineaAgregandoCantidades()
    {
        var userId = Guid.NewGuid();
        var producto = ProductoDobleCarne();
        var carrito = new Cart { Id = Guid.NewGuid(), UsuarioId = userId };
        carrito.Items.Add(LineaDeCarrito(producto, 1));
        carrito.Items.Add(LineaDeCarrito(producto, 1));
        DevolverCarrito(userId, carrito);
        CapturarPedido();

        var service = new OrderService(_uow.Object);
        var respuesta = await service.CreateAsync(userId, new CreateOrderRequest
        {
            DireccionId = Guid.NewGuid(),
            DireccionSnapshot = "casa, norte 56",
            MetodoPago = "efectivo"
        });

        _pedidoGuardado.Should().NotBeNull();
        _pedidoGuardado!.Items.Should().ContainSingle();
        _pedidoGuardado.Items.Single().ProductoId.Should().Be(producto.Id);
        _pedidoGuardado.Items.Single().Cantidad.Should().Be(2);
        _pedidoGuardado.Items.Single().Subtotal.Should().Be(13.00m);
        _pedidoGuardado.Subtotal.Should().Be(13.00m);
        _pedidoGuardado.Total.Should().Be(13.00m);
        respuesta.Total.Should().Be(13.00m);
    }

    [Fact]
    public async Task CreateAsync_ConProductosDiferentes_GeneraUnaLineaPorProducto()
    {
        var userId = Guid.NewGuid();
        var dobleCarne = ProductoDobleCarne();
        var dona = new Product
        {
            Id = Guid.Parse("c0000000-0000-0000-0000-000000000004"),
            Nombre = "Dona Clasica",
            Precio = 1.50m,
            Disponible = true
        };
        var carrito = new Cart { Id = Guid.NewGuid(), UsuarioId = userId };
        carrito.Items.Add(LineaDeCarrito(dobleCarne, 2));
        carrito.Items.Add(LineaDeCarrito(dona, 1));
        DevolverCarrito(userId, carrito);
        CapturarPedido();

        var service = new OrderService(_uow.Object);
        var respuesta = await service.CreateAsync(userId, new CreateOrderRequest { MetodoPago = "tarjeta" });

        _pedidoGuardado.Should().NotBeNull();
        _pedidoGuardado!.Items.Should().HaveCount(2);
        respuesta.Total.Should().Be(14.50m);
    }

    [Fact]
    public async Task CreateAsync_ConDireccionConCoordenadas_CopiaLatitudYLongitudAlPedido()
    {
        var userId = Guid.NewGuid();
        var direccionId = Guid.NewGuid();
        var carrito = new Cart { Id = Guid.NewGuid(), UsuarioId = userId };
        carrito.Items.Add(LineaDeCarrito(ProductoDobleCarne(), 1));
        DevolverCarrito(userId, carrito);
        CapturarPedido();
        _addresses
            .Setup(a => a.GetByIdAsync(direccionId, It.IsAny<CancellationToken>()))
            .ReturnsAsync(new Address { Id = direccionId, Latitud = 13.6929m, Longitud = -89.2182m });

        var service = new OrderService(_uow.Object);
        var respuesta = await service.CreateAsync(userId, new CreateOrderRequest
        {
            DireccionId = direccionId,
            DireccionSnapshot = "casa, norte 56",
            MetodoPago = "efectivo"
        });

        _pedidoGuardado.Should().NotBeNull();
        _pedidoGuardado!.Latitud.Should().Be(13.6929m);
        _pedidoGuardado.Longitud.Should().Be(-89.2182m);
        respuesta.Latitud.Should().Be(13.6929m);
        respuesta.Longitud.Should().Be(-89.2182m);
    }

    [Fact]
    public async Task CreateAsync_SinDireccion_LasCoordenadasQuedanEnNull()
    {
        var userId = Guid.NewGuid();
        var carrito = new Cart { Id = Guid.NewGuid(), UsuarioId = userId };
        carrito.Items.Add(LineaDeCarrito(ProductoDobleCarne(), 1));
        DevolverCarrito(userId, carrito);
        CapturarPedido();

        var service = new OrderService(_uow.Object);
        await service.CreateAsync(userId, new CreateOrderRequest { MetodoPago = "efectivo" });

        _pedidoGuardado.Should().NotBeNull();
        _pedidoGuardado!.Latitud.Should().BeNull();
        _pedidoGuardado.Longitud.Should().BeNull();
    }

    [Fact]
    public async Task CreateAsync_ConDireccionInexistente_LasCoordenadasQuedanEnNull()
    {
        var userId = Guid.NewGuid();
        var direccionId = Guid.NewGuid();
        var carrito = new Cart { Id = Guid.NewGuid(), UsuarioId = userId };
        carrito.Items.Add(LineaDeCarrito(ProductoDobleCarne(), 1));
        DevolverCarrito(userId, carrito);
        CapturarPedido();
        _addresses
            .Setup(a => a.GetByIdAsync(direccionId, It.IsAny<CancellationToken>()))
            .ReturnsAsync((Address?)null);

        var service = new OrderService(_uow.Object);
        await service.CreateAsync(userId, new CreateOrderRequest
        {
            DireccionId = direccionId,
            DireccionSnapshot = "casa, norte 56",
            MetodoPago = "efectivo"
        });

        _pedidoGuardado.Should().NotBeNull();
        _pedidoGuardado!.Latitud.Should().BeNull();
        _pedidoGuardado.Longitud.Should().BeNull();
    }
}
