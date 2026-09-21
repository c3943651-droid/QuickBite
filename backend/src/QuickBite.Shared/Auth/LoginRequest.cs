using System.Text.Json.Serialization;

namespace QuickBite.Shared.Auth;

public sealed record LoginRequest
{
    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("password")]
    public string Password { get; set; } = string.Empty;
}
