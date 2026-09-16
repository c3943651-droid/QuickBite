using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class Address : BaseEntity
{
    public Guid UsuarioId { get; set; }
    public string? Alias { get; set; }
    public string Calle { get; set; } = string.Empty;
    public string? Numero { get; set; }
    public string? Referencia { get; set; }
    public string Ciudad { get; set; } = string.Empty;
    public decimal? Latitud { get; set; }
    public decimal? Longitud { get; set; }
    public bool EsPredeterminada { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public User? Usuario { get; set; }
}
