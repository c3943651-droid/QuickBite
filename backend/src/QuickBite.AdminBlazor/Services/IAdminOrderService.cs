using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Orders;

namespace QuickBite.AdminBlazor.Services;

public interface IAdminOrderService
{
    Task<PagedResult<AdminOrderListItem>?> GetOrdersAsync(OrderListFilter filter, CancellationToken cancellationToken = default);
    Task<AdminOrderDetail?> GetOrderAsync(Guid id, CancellationToken cancellationToken = default);
    Task<OperationResult<bool>> ChangeStatusAsync(Guid id, string estado, string? comentario = null, CancellationToken cancellationToken = default);
    Task<OperationResult<bool>> AssignAsync(Guid id, Guid repartidorId, CancellationToken cancellationToken = default);
    Task<OperationResult<bool>> CancelAsync(Guid id, string motivo, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DeliveryPersonItem>?> GetDeliveryPersonsAsync(string? estado = null, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DeliveryPersonItem>?> GetAvailableDeliveryPersonsAsync(CancellationToken cancellationToken = default);
}