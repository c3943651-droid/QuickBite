using System.Text.Json.Serialization;
namespace QuickBite.Application.Catalog.Dtos;
public sealed record CategoryResponse(Guid Id, string Nombre, string? Descripcion, short Orden, bool Activo, string? Icon);
public sealed record PromotionResponse(Guid Id, string Titulo, string Subtitulo, string ColorHex);
public sealed record CreatePromotionRequest { public string Titulo { get; init; } = ""; public string Subtitulo { get; init; } = ""; public string ColorHex { get; init; } = "#0D9488"; public short Orden { get; init; } }
public sealed record UpdatePromotionRequest { public string? Titulo { get; init; } public string? Subtitulo { get; init; } public string? ColorHex { get; init; } public short? Orden { get; init; } public bool? Activa { get; init; } }
public sealed record CreateCategoryRequest { public string Nombre { get; init; } = ""; public string? Descripcion { get; init; } public short Orden { get; init; } public string? Icon { get; init; } }
public sealed record UpdateCategoryRequest { public string? Nombre { get; init; } public string? Descripcion { get; init; } public short? Orden { get; init; } public bool? Activo { get; init; } public string? Icon { get; init; } }
