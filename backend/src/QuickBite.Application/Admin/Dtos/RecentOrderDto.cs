namespace QuickBite.Application.Admin.Dtos;

public sealed record RecentOrderDto
{
    public Guid Id { get; set; }
    public string NumeroPedido { get; set; } = string.Empty;
    public string Cliente { get; set; } = string.Empty;
    public string Estado { get; set; } = string.Empty;
    public decimal Total { get; set; }
    public DateTime Fecha { get; set; }
}