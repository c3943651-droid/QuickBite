namespace QuickBite.Application.Authentication.Dtos;

public sealed record LogoutRequest
{
    public string RefreshToken { get; init; } = string.Empty;
}
