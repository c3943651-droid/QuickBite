using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Authentication.Models;

namespace QuickBite.Application.Authentication;

public interface IAuthService
{
    Task<RegisterResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);

    Task<AuthResponse> LoginAsync(LoginRequest request, ClientInfo client, CancellationToken cancellationToken = default);

    Task<RefreshResponse> RefreshAsync(RefreshRequest request, ClientInfo client, CancellationToken cancellationToken = default);

    Task LogoutAsync(LogoutRequest request, CancellationToken cancellationToken = default);

    Task<MessageResponse> ForgotPasswordAsync(ForgotPasswordRequest request, CancellationToken cancellationToken = default);

    Task<MessageResponse> ResetPasswordAsync(ResetPasswordRequest request, CancellationToken cancellationToken = default);
}
