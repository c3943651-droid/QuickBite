namespace QuickBite.Application.Admin.Dtos;

public sealed record SalesChartItemDto
{
    public string Dia { get; set; } = string.Empty;
    public decimal Ventas { get; set; }
}