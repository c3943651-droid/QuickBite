namespace QuickBite.Application.Authentication.Dtos;

public sealed record RefreshRequest
{
    public string RefreshToken { get; init; } = string.Empty;
}
