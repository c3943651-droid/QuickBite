using System.Text.Json.Serialization;

namespace QuickBite.Application.Users.Dtos;

public sealed record AddressResponse
{
    public Guid Id { get; init; }
    public string? Alias { get; init; }
    public string Calle { get; init; } = string.Empty;
    public string? Numero { get; init; }
    public string? Referencia { get; init; }
    public string Ciudad { get; init; } = string.Empty;
    public decimal? Latitud { get; init; }
    public decimal? Longitud { get; init; }

    [JsonPropertyName("es_predeterminada")]
    public bool EsPredeterminada { get; init; }

    [JsonPropertyName("creado_en")]
    public DateTime CreadoEn { get; init; }
}
