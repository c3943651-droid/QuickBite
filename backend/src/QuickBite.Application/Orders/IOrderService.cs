using QuickBite.Application.Orders.Dtos;
namespace QuickBite.Application.Orders;
public interface IOrderService
{
    Task<OrderResponse> CreateAsync(Guid userId, CreateOrderRequest req, CancellationToken ct = default);
    Task<IReadOnlyList<OrderResponse>> ListAsync(Guid userId, CancellationToken ct = default);
    Task<OrderDetailResponse> GetAsync(Guid userId, Guid orderId, CancellationToken ct = default);
    Task<OrderStatusResponse> GetStatusAsync(Guid userId, Guid orderId, CancellationToken ct = default);
    Task CancelAsync(Guid userId, Guid orderId, string motivo, CancellationToken ct = default);
}
