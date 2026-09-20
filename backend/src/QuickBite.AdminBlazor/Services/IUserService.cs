using QuickBite.AdminBlazor.Models.Profile;

namespace QuickBite.AdminBlazor.Services;

public interface IUserService
{
    Task<UserProfile?> GetProfileAsync(CancellationToken cancellationToken = default);
    Task<UserProfile?> UpdateProfileAsync(string nombre, string? telefono, CancellationToken cancellationToken = default);
    Task<bool> ChangePasswordAsync(string currentPassword, string newPassword, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<SessionInfo>?> GetSessionsAsync(CancellationToken cancellationToken = default);
    Task<bool> RevokeSessionAsync(Guid id, CancellationToken cancellationToken = default);
}