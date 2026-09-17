using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Users.Dtos;

namespace QuickBite.Application.Users;

public interface IUserService
{
    Task<UserProfileResponse> GetProfileAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<UserProfileResponse> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken cancellationToken = default);

    Task<MessageResponse> ChangePasswordAsync(Guid userId, ChangePasswordRequest request, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<AddressResponse>> GetAddressesAsync(Guid userId, CancellationToken cancellationToken = default);

    Task<AddressResponse> CreateAddressAsync(Guid userId, CreateAddressRequest request, CancellationToken cancellationToken = default);

    Task<AddressResponse> UpdateAddressAsync(Guid userId, Guid addressId, UpdateAddressRequest request, CancellationToken cancellationToken = default);

    Task DeleteAddressAsync(Guid userId, Guid addressId, CancellationToken cancellationToken = default);

    Task<AddressResponse> SetDefaultAddressAsync(Guid userId, Guid addressId, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<SessionResponse>> GetSessionsAsync(Guid userId, string? currentRefreshToken, CancellationToken cancellationToken = default);

    Task RevokeSessionAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken = default);
}
