using QuickBite.AdminBlazor.Models;
using QuickBite.AdminBlazor.Models.Catalog;
using QuickBite.AdminBlazor.Models.Delivery;

namespace QuickBite.AdminBlazor.Services;

public interface IDeliveryPersonService
{
    Task<PagedResult<AdminDeliveryPerson>?> GetDeliveryPersonsAsync(string? estado, int page, int limit, CancellationToken cancellationToken = default);
    Task<OperationResult<AdminDeliveryPerson>> CreateAsync(Guid usuarioId, string? vehiculo, CancellationToken cancellationToken = default);
    Task<OperationResult<AdminDeliveryPerson>> UpdateAsync(Guid id, string? vehiculo, string? estadoDisponibilidad, CancellationToken cancellationToken = default);
    Task<OperationResult<AdminDeliveryPerson>> DeactivateAsync(Guid id, CancellationToken cancellationToken = default);
    Task<PagedResult<AdminDeliveryHistoryItem>?> GetHistoryAsync(Guid id, int page, int limit, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<DeliveryUserCandidate>?> GetAvailableUsersAsync(CancellationToken cancellationToken = default);
}