using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class AuditAction : BaseEntity
{
    public Guid? UsuarioId { get; set; }
    public string Accion { get; set; } = string.Empty;
    public string Entidad { get; set; } = string.Empty;
    public Guid? EntidadId { get; set; }
    public string? Detalles { get; set; }
    public string? IpOrigen { get; set; }
    public string? UserAgent { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public User? Usuario { get; set; }
}
