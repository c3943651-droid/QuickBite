using QuickBite.Application.Orders.Dtos;
namespace QuickBite.Application.Delivery;
public interface IDeliveryService
{
    Task<IReadOnlyList<OrderResponse>> AvailableAsync(Guid repartidorId, CancellationToken ct = default);
    Task AcceptAsync(Guid repartidorId, Guid orderId, CancellationToken ct = default);
    Task<IReadOnlyList<OrderResponse>> ActiveAsync(Guid repartidorId, CancellationToken ct = default);
    Task CompleteAsync(Guid repartidorId, Guid orderId, CancellationToken ct = default);
    Task<IReadOnlyList<OrderResponse>> HistoryAsync(Guid repartidorId, CancellationToken ct = default);
    Task<object> StatsAsync(Guid repartidorId, CancellationToken ct = default);
}
