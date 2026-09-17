namespace QuickBite.Application.Authentication.Dtos;

public sealed record ResetPasswordRequest
{
    public string Token { get; init; } = string.Empty;
    public string NewPassword { get; init; } = string.Empty;
}
