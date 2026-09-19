namespace QuickBite.Shared.Dashboard;

public sealed record SalesChartItemDto
{
    public string Dia { get; set; } = string.Empty;
    public decimal Ventas { get; set; }
}
