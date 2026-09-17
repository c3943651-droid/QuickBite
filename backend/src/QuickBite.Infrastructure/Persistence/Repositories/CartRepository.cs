using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class CartRepository : ICartRepository
{
    private readonly QuickBiteDbContext _db;

    public CartRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<Cart?> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _db.Carritos
            .AsNoTracking()
            .Include(c => c.Items)
                .ThenInclude(i => i.Opciones)
            .Include(c => c.Items)
                .ThenInclude(i => i.Producto)
            .FirstOrDefaultAsync(c => c.UsuarioId == userId && c.Estado == CartStatus.Activo, cancellationToken);
    }

    public async Task AddItemAsync(Guid cartId, CartItem item, CancellationToken cancellationToken = default)
    {
        item.CarritoId = cartId;
        item.AgregadoEn = DateTime.UtcNow;
        await _db.CarritoItems.AddAsync(item, cancellationToken);
    }

    public async Task UpdateItemAsync(CartItem item, CancellationToken cancellationToken = default)
    {
        var tracked = await _db.CarritoItems.FindAsync(new object[] { item.Id }, cancellationToken);
        if (tracked is null)
        {
            return;
        }

        _db.Entry(tracked).CurrentValues.SetValues(item);
    }

    public async Task RemoveItemAsync(Guid cartItemId, CancellationToken cancellationToken = default)
    {
        var item = await _db.CarritoItems.FindAsync(new object[] { cartItemId }, cancellationToken);
        if (item is null)
        {
            return;
        }

        _db.CarritoItems.Remove(item);
    }

    public async Task ClearCartAsync(Guid cartId, CancellationToken cancellationToken = default)
    {
        var items = await _db.CarritoItems
            .Where(i => i.CarritoId == cartId)
            .ToListAsync(cancellationToken);

        _db.CarritoItems.RemoveRange(items);
    }
}