using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class ProductPriceHistory : BaseEntity
{
    public Guid ProductoId { get; set; }
    public decimal PrecioAnterior { get; set; }
    public decimal PrecioNuevo { get; set; }
    public Guid? UsuarioId { get; set; }
    public string? Motivo { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public Product? Producto { get; set; }
    public User? Usuario { get; set; }
}
