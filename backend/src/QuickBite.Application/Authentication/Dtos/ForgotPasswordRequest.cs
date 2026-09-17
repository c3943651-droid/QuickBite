namespace QuickBite.Application.Authentication.Dtos;

public sealed record ForgotPasswordRequest
{
    public string Email { get; init; } = string.Empty;
}
