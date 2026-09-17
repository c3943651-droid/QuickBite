using System.Text.Json.Serialization;
namespace QuickBite.Application.Catalog.Dtos;
public sealed record ProductListItemResponse(Guid Id, string Nombre, string? Descripcion, decimal Precio, string? ImagenUrl, bool Disponible, CategoryResponse? Categoria);
public sealed record ProductDetailResponse(Guid Id, string Nombre, string? Descripcion, decimal Precio, string? ImagenUrl, bool Disponible, CategoryResponse? Categoria, IReadOnlyList<ProductOptionResponse> Opciones, int? Stock);
public sealed record ProductOptionResponse(Guid Id, string Nombre, decimal PrecioAdicional, bool Activo);
public sealed record CreateProductRequest { public string Nombre { get; init; } = ""; public string? Descripcion { get; init; } public decimal Precio { get; init; } public Guid? CategoriaId { get; init; } public string? ImagenUrl { get; init; } public bool Disponible { get; init; } = true; public int StockInicial { get; init; } public int StockMinimo { get; init; } }
public sealed record UpdateProductRequest { public string? Nombre { get; init; } public string? Descripcion { get; init; } public decimal? Precio { get; init; } public Guid? CategoriaId { get; init; } public string? ImagenUrl { get; init; } public bool? Disponible { get; init; } }
public sealed record CreateProductOptionRequest { public string Nombre { get; init; } = ""; public decimal PrecioAdicional { get; init; } public bool Activo { get; init; } = true; }
public sealed record UpdateProductOptionRequest { public string? Nombre { get; init; } public decimal? PrecioAdicional { get; init; } public bool? Activo { get; init; } }
public sealed record ProductFilterRequest { public Guid? CategoriaId { get; init; } public string? Search { get; init; } public bool? Disponible { get; init; } public decimal? PrecioMin { get; init; } public decimal? PrecioMax { get; init; } public string? Orden { get; init; } public int Page { get; init; } = 1; public int Limit { get; init; } = 10; }
public sealed record PagedResponse<T>(IReadOnlyList<T> Data, int Total, int Page, int Limit, int TotalPages);
