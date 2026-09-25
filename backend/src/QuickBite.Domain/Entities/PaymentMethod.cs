using QuickBite.Domain.Common;

namespace QuickBite.Domain.Entities;

public class PaymentMethod : BaseEntity
{
    public string Nombre { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
    public bool Activo { get; set; } = true;
}
