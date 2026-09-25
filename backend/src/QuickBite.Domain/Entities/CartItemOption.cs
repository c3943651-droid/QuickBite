using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class CartItemOption : BaseEntity
{
    public Guid CarritoItemId { get; set; }
    public Guid OpcionId { get; set; }

    // Relaciones de navegación
    public CartItem? CarritoItem { get; set; }
    public ProductOption? Opcion { get; set; }
}
