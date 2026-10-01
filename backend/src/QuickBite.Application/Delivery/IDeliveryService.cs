using QuickBite.Application.Delivery.Dtos;
using QuickBite.Domain.Enums;
namespace QuickBite.Application.Delivery;
public interface IDeliveryService
{
    Task<IReadOnlyList<DeliveryOrderResponse>> AvailableAsync(Guid repartidorId, CancellationToken ct = default);
    Task AcceptAsync(Guid repartidorId, Guid orderId, CancellationToken ct = default);
    Task<IReadOnlyList<DeliveryOrderResponse>> ActiveAsync(Guid repartidorId, CancellationToken ct = default);
    Task CompleteAsync(Guid repartidorId, Guid orderId, CancellationToken ct = default);
    Task<IReadOnlyList<DeliveryOrderResponse>> HistoryAsync(Guid repartidorId, CancellationToken ct = default);
    Task<DeliveryPersonStatsDto> StatsAsync(Guid repartidorId, CancellationToken ct = default);

    /// Cambia el estado de disponibilidad del repartidor autenticado y devuelve
    /// el estado resultante. Rechaza marcarlo disponible si tiene entregas en
    /// camino (07.1 SCR-DEL-07).
    Task<DeliveryAvailabilityDto> SetAvailabilityAsync(Guid repartidorId, DeliveryPersonStatus estado, CancellationToken ct = default);
}
