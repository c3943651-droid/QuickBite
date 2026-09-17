using QuickBite.Application.Orders.Dtos;
using QuickBite.Domain.Enums;
namespace QuickBite.Application.Admin;
public interface IAdminOrderService
{
    Task<IReadOnlyList<OrderResponse>> ListAsync(OrderStatus? status, Guid? repartidorId, CancellationToken ct = default);
    Task<OrderResponse> UpdateStatusAsync(Guid orderId, OrderStatus status, CancellationToken ct = default);
    Task CancelAsync(Guid orderId, string motivo, CancellationToken ct = default);
    Task AssignAsync(Guid orderId, Guid repartidorId, AssignmentOrigin origin, CancellationToken ct = default);
    Task<object> DashboardAsync(CancellationToken ct = default);
}
