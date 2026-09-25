using QuickBite.Domain.Common;
using QuickBite.Domain.Enums;

namespace QuickBite.Domain.Entities;

public class User : BaseEntity
{
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? Telefono { get; set; }
    public UserRole Rol { get; set; } = UserRole.Cliente;
    public bool Activo { get; set; } = true;
    public short IntentosFallidos { get; set; } = 0;
    public DateTime? BloqueadoHasta { get; set; }
    public DateTime? UltimoLogin { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;
    public DateTime ActualizadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public ICollection<Address> Direcciones { get; set; } = new List<Address>();
    public DeliveryPerson? Repartidor { get; set; }
    public ICollection<RefreshToken> TokensRefresco { get; set; } = new List<RefreshToken>();
    public ICollection<PasswordResetToken> TokensRecuperacion { get; set; } = new List<PasswordResetToken>();
    public Cart? Carrito { get; set; }
    public ICollection<Order> Pedidos { get; set; } = new List<Order>();
    public ICollection<Notification> Notificaciones { get; set; } = new List<Notification>();
    public ICollection<AuditAction> Auditorias { get; set; } = new List<AuditAction>();
}
