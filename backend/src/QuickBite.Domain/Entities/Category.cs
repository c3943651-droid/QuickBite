using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class Category : BaseEntity
{
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public short Orden { get; set; }
    public bool Activo { get; set; } = true;
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public ICollection<Product> Productos { get; set; } = new List<Product>();
}
