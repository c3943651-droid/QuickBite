namespace QuickBite.Domain.Repositories.Models;

public class DeliveryPersonStats
{
    public Guid DeliveryPersonId { get; set; }
    public int EntregasTotales { get; set; }
    public int EntregasDelMes { get; set; }
    public double TiempoPromedioEntregaMinutos { get; set; }
    public int PedidosAsignadosActivos { get; set; }
    public int Cancelaciones { get; set; }
}
