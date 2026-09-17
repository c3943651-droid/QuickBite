using System.Text.Json.Serialization;

namespace QuickBite.Application.Users.Dtos;

public sealed record UserProfileResponse
{
    public Guid Id { get; init; }
    public string Nombre { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string? Telefono { get; init; }
    public string Rol { get; init; } = string.Empty;

    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; init; }

    [JsonPropertyName("ultimo_login")]
    public DateTime? UltimoLogin { get; init; }
}
