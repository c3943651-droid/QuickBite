using MudBlazor;

namespace QuickBite.AdminBlazor.Models.Orders;

public sealed record AdminOrderListItem(
    Guid Id,
    string NumeroPedido,
    string Cliente,
    string Estado,
    decimal Total,
    DateTime CreadoEn,
    string? Repartidor);

public sealed record AdminOrderItemOption(string Nombre, decimal PrecioAdicional);

public sealed record AdminOrderItem(
    Guid Id,
    string NombreProducto,
    decimal PrecioUnitario,
    short Cantidad,
    string? Observaciones,
    decimal Subtotal,
    IReadOnlyList<AdminOrderItemOption> Opciones);

public sealed record AdminOrderStatusHistory(
    Guid Id,
    string? EstadoAnterior,
    string EstadoNuevo,
    string? Usuario,
    string? Comentario,
    DateTime CreadoEn);

public sealed record AdminOrderAudit(
    Guid Id,
    string Accion,
    string? Usuario,
    string? IpOrigen,
    DateTime CreadoEn,
    string? Detalles);

public sealed record AdminOrderDetail(
    Guid Id,
    string NumeroPedido,
    string Estado,
    DateTime CreadoEn,
    string? MotivoCancelacion,
    string ClienteNombre,
    string? ClienteEmail,
    string? ClienteTelefono,
    string DireccionEntregaSnapshot,
    string? RepartidorNombre,
    string? RepartidorTelefono,
    string? RepartidorEstado,
    decimal Subtotal,
    decimal CostoEnvio,
    decimal Total,
    IReadOnlyList<AdminOrderItem> Items,
    IReadOnlyList<AdminOrderStatusHistory> HistorialEstados,
    IReadOnlyList<AdminOrderAudit> Auditoria);

public sealed record DeliveryPersonItem(Guid UsuarioId, string Nombre, string? Telefono, string? EstadoDisponibilidad, string? Vehiculo, int? EntregasCompletadas);

public sealed class OrderListFilter
{
    public string? Search { get; set; }
    public string? Estado { get; set; }
    public Guid? RepartidorId { get; set; }
    public DateTime? FechaDesde { get; set; }
    public DateTime? FechaHasta { get; set; }
    public int Page { get; set; } = 1;
    public int Limit { get; set; } = 10;
}

public static class OrderStatusUi
{
    public static IReadOnlyList<string> All { get; } = new[] { "Pendiente", "Confirmado", "Preparando", "Listo", "EnCamino", "Entregado", "Cancelado" };

    private static readonly IReadOnlyDictionary<string, string[]> Transitions =
        new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase)
        {
            ["Pendiente"] = new[] { "Confirmado", "Cancelado" },
            ["Confirmado"] = new[] { "Preparando", "Cancelado" },
            ["Preparando"] = new[] { "Listo", "Cancelado" },
            ["Listo"] = new[] { "EnCamino", "Cancelado" },
            ["EnCamino"] = new[] { "Entregado" },
            ["Entregado"] = Array.Empty<string>(),
            ["Cancelado"] = Array.Empty<string>(),
        };

    public static IReadOnlyList<string> ValidTransitions(string estado) =>
        Transitions.TryGetValue(estado, out var targets) ? targets : Array.Empty<string>();

    public static string Display(string estado) => estado switch
    {
        "EnCamino" => "En camino",
        _ => estado,
    };

    public static Color Color(string estado) => estado.ToLowerInvariant() switch
    {
        "pendiente" => MudBlazor.Color.Warning,
        "confirmado" => MudBlazor.Color.Info,
        "preparando" => MudBlazor.Color.Secondary,
        "listo" => MudBlazor.Color.Primary,
        "encamino" => MudBlazor.Color.Tertiary,
        "entregado" => MudBlazor.Color.Success,
        "cancelado" => MudBlazor.Color.Error,
        _ => MudBlazor.Color.Default,
    };
}