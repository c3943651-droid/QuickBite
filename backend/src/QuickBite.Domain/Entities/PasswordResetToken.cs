using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class PasswordResetToken : BaseEntity
{
    public Guid UsuarioId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public DateTime ExpiraEn { get; set; }
    public bool Usado { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public User? Usuario { get; set; }
}
