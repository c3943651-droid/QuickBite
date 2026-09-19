namespace QuickBite.Shared.Dashboard;

public sealed record DashboardDataDto
{
    public int TotalPedidos { get; set; }
    public decimal VentasTotales { get; set; }
    public int Pendientes { get; set; }
    public Dictionary<string, int> PorEstado { get; set; } = new();
    public List<SalesChartItemDto> SalesChart { get; set; } = new();
    public List<RecentOrderDto> RecentOrders { get; set; } = new();
}
