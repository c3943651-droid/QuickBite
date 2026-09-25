using System.Text.Json.Serialization;

namespace QuickBite.Application.Authentication.Dtos;

public sealed record RegisterResponse
{
    public Guid Id { get; init; }
    public string Nombre { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
    public string Rol { get; init; } = string.Empty;

    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; init; }
}
