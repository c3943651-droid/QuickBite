using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class ProductOption : BaseEntity
{
    public Guid ProductoId { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public decimal PrecioAdicional { get; set; }
    public bool Activo { get; set; } = true;

    // Relaciones de navegación
    public Product? Producto { get; set; }
}
