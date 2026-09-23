using QuickBite.Domain.Entities;

namespace QuickBite.Domain.Repositories;

public interface ICartRepository
{
    Task<Cart?> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task AddAsync(Cart cart, CancellationToken cancellationToken = default);
    Task AddItemAsync(Guid cartId, CartItem item, CancellationToken cancellationToken = default);
    Task UpdateItemAsync(CartItem item, CancellationToken cancellationToken = default);
    Task RemoveItemAsync(Guid cartItemId, CancellationToken cancellationToken = default);
    Task ClearCartAsync(Guid cartId, CancellationToken cancellationToken = default);
}
