namespace QuickBite.Domain.Repositories.Models;

public class VentaPorDiaRow
{
    public DateTime Dia { get; set; }
    public int TotalPedidos { get; set; }
    public int Entregados { get; set; }
    public int Cancelados { get; set; }
    public int Activos { get; set; }
    public decimal Ingresos { get; set; }
    public decimal TicketPromedio { get; set; }
}

public class ProductoMasVendidoRow
{
    public Guid ProductoId { get; set; }
    public string NombreProducto { get; set; } = string.Empty;
    public int UnidadesVendidas { get; set; }
    public decimal IngresosGenerados { get; set; }
    public int NumeroPedidos { get; set; }
}

public class ClienteFrecuenteRow
{
    public Guid ClienteId { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public int TotalPedidos { get; set; }
    public decimal GastoTotal { get; set; }
    public decimal GastoPromedio { get; set; }
    public DateTime? UltimoPedido { get; set; }
}

public class RendimientoRepartidorRow
{
    public Guid RepartidorId { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public int EntregasCompletadas { get; set; }
    public int PedidosAsignados { get; set; }
    public double MinutosPromedioEntrega { get; set; }
    public int Cancelaciones { get; set; }
}