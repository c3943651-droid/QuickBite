using QuickBite.Domain.Enums;

namespace QuickBite.Domain.Entities;

public class DeliveryPerson
{
    public Guid UsuarioId { get; set; }
    public DeliveryPersonStatus EstadoDisponibilidad { get; set; } = DeliveryPersonStatus.Inactivo;
    public string? Vehiculo { get; set; }
    public int EntregasCompletadas { get; set; }
    public DateTime FechaAlta { get; set; } = DateTime.UtcNow;

    // Relaciones de navegación
    public User? Usuario { get; set; }
    public ICollection<Order> Pedidos { get; set; } = new List<Order>();
}
