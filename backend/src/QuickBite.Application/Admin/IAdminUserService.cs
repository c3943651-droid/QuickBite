using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Catalog.Dtos;

namespace QuickBite.Application.Admin;

public interface IAdminUserService
{
    Task<PagedResponse<AdminUserListItemResponse>> ListAsync(string? search, string? rol, bool? activo, int page, int limit, CancellationToken ct = default);
    Task<AdminUserDetailResponse> GetByIdAsync(Guid id, CancellationToken ct = default);
    Task<AdminUserDetailResponse> UpdateRoleAsync(Guid id, UpdateUserRoleRequest request, Guid currentUserId, CancellationToken ct = default);
    Task<AdminUserDetailResponse> UpdateStatusAsync(Guid id, UpdateUserStatusRequest request, Guid currentUserId, CancellationToken ct = default);
}