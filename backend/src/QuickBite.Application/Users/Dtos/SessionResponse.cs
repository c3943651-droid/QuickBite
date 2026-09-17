using System.Text.Json.Serialization;

namespace QuickBite.Application.Users.Dtos;

public sealed record SessionResponse
{
    public Guid Id { get; init; }

    [JsonPropertyName("ip_origen")]
    public string? IpOrigen { get; init; }

    [JsonPropertyName("user_agent")]
    public string? UserAgent { get; init; }

    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; init; }

    [JsonPropertyName("expira_en")]
    public DateTime ExpiraEn { get; init; }

    [JsonPropertyName("es_actual")]
    public bool EsActual { get; init; }
}
