using QuickBite.Domain.Common;
using QuickBite.Domain.Enums;

namespace QuickBite.Domain.Entities;

public class Notification : BaseEntity
{
    public Guid UsuarioId { get; set; }
    public NotificationType Tipo { get; set; }
    public string Titulo { get; set; } = string.Empty;
    public string Mensaje { get; set; } = string.Empty;
    public Guid? PedidoId { get; set; }
    public bool Leido { get; set; }
    public DateTime? LeidoEn { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public User? Usuario { get; set; }
    public Order? Pedido { get; set; }
}
