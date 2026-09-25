using QuickBite.Domain.Common;
using QuickBite.Domain.Enums;

namespace QuickBite.Domain.Entities;

public class Cart : BaseEntity
{
    public Guid UsuarioId { get; set; }
    public DateTime ActualizadoEn { get; set; } = DateTime.UtcNow;
    public DateTime UltimoAcceso { get; set; } = DateTime.UtcNow;
    public DateTime ExpiraEn { get; set; } = DateTime.UtcNow.AddHours(24);
    public CartStatus Estado { get; set; } = CartStatus.Activo;

    // Relaciones de navegación
    public User? Usuario { get; set; }
    public ICollection<CartItem> Items { get; set; } = new List<CartItem>();
}
