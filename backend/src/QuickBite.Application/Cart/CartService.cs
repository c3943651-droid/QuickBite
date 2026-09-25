using QuickBite.Application.Cart.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
namespace QuickBite.Application.Cart;
public sealed class CartService : ICartService
{
    private readonly IUnitOfWork _uow;
    public CartService(IUnitOfWork uow) { _uow = uow; }
    private static CartResponse ToResponse(Domain.Entities.Cart c)
    {
        var items = c.Items.Select(i => new CartItemResponse(i.Id, i.ProductoId, i.Producto?.Nombre ?? "", i.Producto?.Precio ?? 0, i.Cantidad, i.Opciones.Select(o => o.Opcion?.Nombre ?? "").ToList(), (i.Producto?.Precio ?? 0) * i.Cantidad)).ToList();
        return new CartResponse(c.Id, items, items.Sum(x => x.Subtotal));
    }
    private async Task<Domain.Entities.Cart> GetOrCreateAsync(Guid userId, CancellationToken ct)
    {
        var cart = await _uow.Carts.GetActiveByUserIdAsync(userId, ct);
        if (cart != null) return cart;

        cart = new Domain.Entities.Cart { UsuarioId = userId };
        await _uow.Carts.AddAsync(cart, ct);
        return cart;
    }
    public async Task<CartResponse> GetAsync(Guid userId, CancellationToken ct = default)
    {
        var cart = await _uow.Carts.GetActiveByUserIdAsync(userId, ct);
        if (cart == null) return new CartResponse(Guid.Empty, [], 0);
        return ToResponse(cart);
    }
    public async Task<CartResponse> AddItemAsync(Guid userId, AddCartItemRequest req, CancellationToken ct = default)
    {
        var product = await _uow.Products.GetByIdAsync(req.ProductoId, ct) ?? throw new NotFoundException("Producto", req.ProductoId);
        if (!product.Disponible) throw new BusinessRuleException("Producto no disponible");
        if (product.Inventario != null && product.Inventario.Stock < req.Cantidad) throw new BusinessRuleException("Stock insuficiente");
        var cart = await GetOrCreateAsync(userId, ct);
        var item = new CartItem { CarritoId = cart.Id, ProductoId = req.ProductoId, Cantidad = req.Cantidad, Observaciones = req.Observaciones };
        foreach (var optId in req.OpcionesIds)
        {
            var opt = product.Opciones.FirstOrDefault(o => o.Id == optId && o.Activo) ?? throw new NotFoundException("Opcion", optId);
            item.Opciones.Add(new CartItemOption { OpcionId = optId });
        }
        await _uow.Carts.AddItemAsync(cart.Id, item, ct);
        await _uow.SaveChangesAsync(ct);
        var updated = await _uow.Carts.GetActiveByUserIdAsync(userId, ct);
        return ToResponse(updated ?? cart);
    }
    public async Task<CartResponse> UpdateItemAsync(Guid userId, Guid itemId, UpdateCartItemRequest req, CancellationToken ct = default)
    {
        var cart = await _uow.Carts.GetActiveByUserIdAsync(userId, ct) ?? throw new NotFoundException("Carrito", userId);
        var item = cart.Items.FirstOrDefault(i => i.Id == itemId) ?? throw new NotFoundException("Item", itemId);
        item.Cantidad = req.Cantidad; item.Observaciones = req.Observaciones;
        await _uow.Carts.UpdateItemAsync(item, ct);
        await _uow.SaveChangesAsync(ct);
        var upd = await _uow.Carts.GetActiveByUserIdAsync(userId, ct);
        return ToResponse(upd!);
    }
    public async Task RemoveItemAsync(Guid userId, Guid itemId, CancellationToken ct = default)
    {
        var cart = await _uow.Carts.GetActiveByUserIdAsync(userId, ct) ?? throw new NotFoundException("Carrito", userId);
        if (!cart.Items.Any(i => i.Id == itemId)) throw new NotFoundException("Item", itemId);
        await _uow.Carts.RemoveItemAsync(itemId, ct);
        await _uow.SaveChangesAsync(ct);
    }
    public async Task ClearAsync(Guid userId, CancellationToken ct = default)
    {
        var cart = await _uow.Carts.GetActiveByUserIdAsync(userId, ct);
        if (cart == null) return;
        await _uow.Carts.ClearCartAsync(cart.Id, ct);
        await _uow.SaveChangesAsync(ct);
    }
}
