using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class Product : BaseEntity
{
    public Guid? CategoriaId { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public decimal Precio { get; set; }
    public string? ImagenUrl { get; set; }
    public bool Disponible { get; set; } = true;
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;
    public DateTime ActualizadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public Category? Categoria { get; set; }
    public Inventory? Inventario { get; set; }
    public ICollection<ProductOption> Opciones { get; set; } = new List<ProductOption>();
    public ICollection<ProductPriceHistory> PreciosHistoricos { get; set; } = new List<ProductPriceHistory>();
}
