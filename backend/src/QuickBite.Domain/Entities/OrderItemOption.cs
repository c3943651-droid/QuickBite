using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class OrderItemOption : BaseEntity
{
    public Guid PedidoItemId { get; set; }
    public string NombreOpcion { get; set; } = string.Empty;
    public decimal PrecioAdicional { get; set; }

    // Relaciones de navegación
    public OrderItem? PedidoItem { get; set; }
}
