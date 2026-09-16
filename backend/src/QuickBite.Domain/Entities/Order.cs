using QuickBite.Domain.Common;
using QuickBite.Domain.Enums;

namespace QuickBite.Domain.Entities;

public class Order : BaseEntity
{
    public string NumeroPedido { get; set; } = string.Empty;
    public Guid ClienteId { get; set; }
    public Guid? RepartidorId { get; set; }
    public Guid? DireccionId { get; set; }
    public string DireccionEntregaSnapshot { get; set; } = string.Empty;
    public OrderStatus Estado { get; set; } = OrderStatus.Pendiente;
    public PaymentMethodType MetodoPago { get; set; } = PaymentMethodType.Efectivo;
    public Guid? MetodoPagoId { get; set; }
    public decimal Subtotal { get; set; }
    public decimal CostoEnvio { get; set; }
    public decimal Total { get; set; }
    public string? MotivoCancelacion { get; set; }
    public DateTime? ConfirmadoEn { get; set; }
    public DateTime? PreparandoEn { get; set; }
    public DateTime? ListoEn { get; set; }
    public DateTime? EnCaminoEn { get; set; }
    public DateTime? EntregadoEn { get; set; }
    public DateTime? CanceladoEn { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;
    public DateTime ActualizadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public User? Cliente { get; set; }
    public DeliveryPerson? Repartidor { get; set; }
    public Address? Direccion { get; set; }
    public PaymentMethod? MetodoPagoCatalogo { get; set; }
    public ICollection<OrderItem> Items { get; set; } = new List<OrderItem>();
    public ICollection<OrderStatusHistory> HistorialEstados { get; set; } = new List<OrderStatusHistory>();
    public ICollection<Notification> Notificaciones { get; set; } = new List<Notification>();
}
