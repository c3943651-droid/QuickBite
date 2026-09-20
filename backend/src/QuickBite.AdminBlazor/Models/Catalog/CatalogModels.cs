namespace QuickBite.AdminBlazor.Models.Catalog;

public enum OrderStatus
{
    Pendiente = 1,
    Confirmado = 2,
    Preparando = 3,
    Listo = 4,
    EnCamino = 5,
    Entregado = 6,
    Cancelado = 7
}

public sealed record CategoryItem(Guid Id, string Nombre, string? Descripcion, short Orden, bool Activo);

public sealed record ProductListItem(
    Guid Id,
    string Nombre,
    string? Descripcion,
    decimal Precio,
    string? ImagenUrl,
    bool Disponible,
    CategoryItem? Categoria,
    int? Stock = null,
    int? StockMinimo = null);

public sealed record ProductOption(Guid Id, string Nombre, decimal PrecioAdicional, bool Activo);

public sealed record ProductDetail(
    Guid Id,
    string Nombre,
    string? Descripcion,
    decimal Precio,
    string? ImagenUrl,
    bool Disponible,
    CategoryItem? Categoria,
    IReadOnlyList<ProductOption> Opciones,
    int? Stock);

public sealed record PriceHistoryItem(
    Guid Id,
    decimal PrecioAnterior,
    decimal PrecioNuevo,
    string? Usuario,
    string? Motivo,
    DateTime CreadoEn);

public sealed record PagedResult<T>(IReadOnlyList<T> Data, int Total, int Page, int Limit, int TotalPages);

public sealed record ProductFilter(Guid? CategoriaId = null, string? Search = null, bool? Disponible = null, int Page = 1, int Limit = 10);

public sealed class ProductSaveRequest
{
    public string Nombre { get; init; } = "";
    public string? Descripcion { get; init; }
    public decimal Precio { get; init; }
    public Guid? CategoriaId { get; init; }
    public string? ImagenUrl { get; init; }
    public bool Disponible { get; init; } = true;
    public int StockInicial { get; init; }
    public int StockMinimo { get; init; }
}

public sealed class ProductFormModel
{
    public string Nombre { get; set; } = "";
    public string? Descripcion { get; set; }
    public decimal Precio { get; set; }
    public Guid? CategoriaId { get; set; }
    public string? ImagenUrl { get; set; }
    public bool Disponible { get; set; } = true;
    public int StockInicial { get; set; }
    public int StockMinimo { get; set; }
    public List<OptionFormModel> Opciones { get; set; } = new();
}

public sealed class OptionFormModel
{
    public Guid? Id { get; set; }
    public string Nombre { get; set; } = "";
    public decimal PrecioAdicional { get; set; }
    public bool Activo { get; set; } = true;
}

public sealed record OptionSaveRequest(string Nombre, decimal PrecioAdicional, bool Activo);