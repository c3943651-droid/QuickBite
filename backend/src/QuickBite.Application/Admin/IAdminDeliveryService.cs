using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Catalog.Dtos;

namespace QuickBite.Application.Admin;

public interface IAdminDeliveryService
{
    Task<PagedResponse<DeliveryPersonListItemResponse>> ListAsync(string? estado, int page, int limit, CancellationToken ct = default);
    Task<DeliveryPersonListItemResponse> CreateAsync(CreateDeliveryPersonRequest req, CancellationToken ct = default);
    Task<DeliveryPersonListItemResponse> UpdateAsync(Guid id, UpdateDeliveryPersonRequest req, CancellationToken ct = default);
    Task<DeliveryPersonListItemResponse> DeactivateAsync(Guid id, CancellationToken ct = default);
    Task<PagedResponse<DeliveryPersonHistoryResponse>> GetHistoryAsync(Guid id, int page, int limit, CancellationToken ct = default);
    Task<IReadOnlyList<DeliveryUserCandidateResponse>> GetAvailableUsersAsync(CancellationToken ct = default);
}