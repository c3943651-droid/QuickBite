namespace QuickBite.Domain.Entities;

public class Inventory
{
    public Guid ProductoId { get; set; }
    public int Stock { get; set; }
    public int StockMinimo { get; set; }
    public DateTime UltimaActualizacion { get; set; } = DateTime.UtcNow;
    public Guid? ActualizadoPor { get; set; }

    // Relaciones de navegación
    public Product? Producto { get; set; }
    public User? ActualizadoPorUsuario { get; set; }
}
