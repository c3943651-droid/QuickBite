using QuickBite.Domain.Common;
using QuickBite.Domain.Enums;

namespace QuickBite.Domain.Entities;

public class OrderStatusHistory : BaseEntity
{
    public Guid PedidoId { get; set; }
    public OrderStatus? EstadoAnterior { get; set; }
    public OrderStatus EstadoNuevo { get; set; }
    public Guid? UsuarioId { get; set; }
    public string? Comentario { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public Order? Pedido { get; set; }
    public User? Usuario { get; set; }
}
