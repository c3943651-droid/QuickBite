using System.Text.Json.Serialization;

namespace QuickBite.Shared.Auth;

public sealed record AuthResponse
{
    [JsonPropertyName("accessToken")]
    public string AccessToken { get; init; } = string.Empty;

    [JsonPropertyName("refreshToken")]
    public string RefreshToken { get; init; } = string.Empty;

    [JsonPropertyName("expiresIn")]
    public int ExpiresIn { get; init; }

    [JsonPropertyName("user")]
    public UserSummaryDto User { get; init; } = new();
}
