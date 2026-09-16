using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class OrderItem : BaseEntity
{
    public Guid PedidoId { get; set; }
    public Guid? ProductoId { get; set; }
    public string NombreProducto { get; set; } = string.Empty;
    public decimal PrecioUnitario { get; set; }
    public short Cantidad { get; set; } = 1;
    public string? Observaciones { get; set; }
    public decimal Subtotal { get; set; }

    // Relaciones de navegación
    public Order? Pedido { get; set; }
    public Product? Producto { get; set; }
    public ICollection<OrderItemOption> Opciones { get; set; } = new List<OrderItemOption>();
}
