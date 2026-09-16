using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class CartItem : BaseEntity
{
    public Guid CarritoId { get; set; }
    public Guid ProductoId { get; set; }
    public short Cantidad { get; set; } = 1;
    public string? Observaciones { get; set; }
    public DateTime AgregadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public Cart? Carrito { get; set; }
    public Product? Producto { get; set; }
    public ICollection<CartItemOption> Opciones { get; set; } = new List<CartItemOption>();
}
