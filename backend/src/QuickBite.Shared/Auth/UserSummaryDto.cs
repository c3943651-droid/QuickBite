using System.Text.Json.Serialization;

namespace QuickBite.Shared.Auth;

public sealed record UserSummaryDto
{
    [JsonPropertyName("id")]
    public Guid Id { get; init; }

    [JsonPropertyName("nombre")]
    public string Nombre { get; init; } = string.Empty;

    [JsonPropertyName("email")]
    public string Email { get; init; } = string.Empty;

    [JsonPropertyName("rol")]
    public string Rol { get; init; } = string.Empty;
}
