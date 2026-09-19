using QuickBite.Shared.Auth;

namespace QuickBite.AdminBlazor.Services;

public interface IAuthService
{
    Task<AuthResult> LoginAsync(LoginRequest request);
    Task LogoutAsync();
    UserSummaryDto? CurrentUser { get; }
    bool IsAuthenticated { get; }
}

public sealed record AuthResult
{
    public bool Succeeded { get; init; }
    public string? ErrorMessage { get; init; }

    public static AuthResult Success() => new() { Succeeded = true };
    public static AuthResult Failure(string message) => new() { Succeeded = false, ErrorMessage = message };
}
