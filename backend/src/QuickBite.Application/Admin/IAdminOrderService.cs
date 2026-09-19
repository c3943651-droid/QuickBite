using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Catalog.Dtos;
using QuickBite.Application.Orders.Dtos;
using QuickBite.Domain.Enums;
namespace QuickBite.Application.Admin;
public interface IAdminOrderService
{
    Task<PagedResponse<AdminOrderListItemResponse>> ListAsync(string? search, OrderStatus? status, Guid? repartidorId, DateTime? fechaDesde, DateTime? fechaHasta, int page, int limit, CancellationToken ct = default);
    Task<AdminOrderDetailResponse?> GetAsync(Guid orderId, CancellationToken ct = default);
    Task<OrderResponse> UpdateStatusAsync(Guid orderId, OrderStatus status, string? comentario = null, CancellationToken ct = default);
    Task CancelAsync(Guid orderId, string motivo, CancellationToken ct = default);
    Task AssignAsync(Guid orderId, Guid repartidorId, AssignmentOrigin origin, CancellationToken ct = default);
    Task<object> DashboardAsync(CancellationToken ct = default);
}