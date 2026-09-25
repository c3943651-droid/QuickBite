using System.Text.Json.Serialization;

namespace QuickBite.Application.Users.Dtos;

public sealed record UpdateAddressRequest
{
    public string? Alias { get; init; }
    public string? Calle { get; init; }
    public string? Numero { get; init; }
    public string? Referencia { get; init; }
    public string? Ciudad { get; init; }
    public decimal? Latitud { get; init; }
    public decimal? Longitud { get; init; }

    [JsonPropertyName("es_predeterminada")]
    public bool? EsPredeterminada { get; init; }
}
