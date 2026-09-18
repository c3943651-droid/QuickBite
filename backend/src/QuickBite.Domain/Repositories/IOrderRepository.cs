using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;

namespace QuickBite.Domain.Repositories;

public interface IOrderRepository
{
    Task AddAsync(Order order, CancellationToken cancellationToken = default);
    Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<Order?> GetByOrderNumberAsync(string orderNumber, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Order>> GetOrdersAsync(Guid? clientId = null, Guid? deliveryPersonId = null, OrderStatus? status = null, CancellationToken cancellationToken = default);
    Task<(IReadOnlyList<Order> Items, int TotalCount)> GetDeliveredByDeliveryPersonPagedAsync(Guid deliveryPersonId, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<bool> HasActiveOrdersAsync(Guid deliveryPersonId, CancellationToken cancellationToken = default);
    Task UpdateStatusAsync(Guid orderId, OrderStatus newStatus, string? comment = null, Guid? userId = null, CancellationToken cancellationToken = default);
    Task AssignDeliveryPersonAsync(Guid orderId, Guid deliveryPersonId, AssignmentOrigin origin, CancellationToken cancellationToken = default);
    Task CancelOrderAsync(Guid orderId, string reason, Guid? userId = null, CancellationToken cancellationToken = default);
}
