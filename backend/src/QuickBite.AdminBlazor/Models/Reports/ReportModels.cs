namespace QuickBite.AdminBlazor.Models.Reports;

public sealed record SalesByDayRow(
    DateTime Dia,
    int TotalPedidos,
    int Entregados,
    int Cancelados,
    int Activos,
    decimal Ingresos,
    decimal TicketPromedio);

public sealed record TopProductRow(
    Guid ProductoId,
    string NombreProducto,
    int UnidadesVendidas,
    decimal IngresosGenerados,
    int NumeroPedidos);

public sealed record TopClientRow(
    Guid ClienteId,
    string Nombre,
    string Email,
    int TotalPedidos,
    decimal GastoTotal,
    decimal GastoPromedio,
    DateTime? UltimoPedido);

public sealed record DeliveryPerformanceRow(
    Guid RepartidorId,
    string Nombre,
    int EntregasCompletadas,
    int PedidosAsignados,
    double MinutosPromedioEntrega,
    int Cancelaciones);

public static class ReportLimits
{
    public static IReadOnlyList<int> Available { get; } = new[] { 10, 20, 50 };
}