using System.Text.Json.Serialization;
namespace QuickBite.Application.Catalog.Dtos;
public sealed record CategoryResponse(Guid Id, string Nombre, string? Descripcion, short Orden, bool Activo, string? Icon);
public sealed record CreateCategoryRequest { public string Nombre { get; init; } = ""; public string? Descripcion { get; init; } public short Orden { get; init; } public string? Icon { get; init; } }
public sealed record UpdateCategoryRequest { public string? Nombre { get; init; } public string? Descripcion { get; init; } public short? Orden { get; init; } public bool? Activo { get; init; } public string? Icon { get; init; } }
