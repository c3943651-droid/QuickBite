using QuickBite.Application.Cart.Dtos;
namespace QuickBite.Application.Cart;
public interface ICartService
{
    Task<CartResponse> GetAsync(Guid userId, CancellationToken ct = default);
    Task<CartResponse> AddItemAsync(Guid userId, AddCartItemRequest req, CancellationToken ct = default);
    Task<CartResponse> UpdateItemAsync(Guid userId, Guid itemId, UpdateCartItemRequest req, CancellationToken ct = default);
    Task RemoveItemAsync(Guid userId, Guid itemId, CancellationToken ct = default);
    Task ClearAsync(Guid userId, CancellationToken ct = default);
}
