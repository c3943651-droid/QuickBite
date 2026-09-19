using MudBlazor;

namespace QuickBite.AdminBlazor.Models.Delivery;

public sealed record AdminDeliveryPerson(
    Guid UsuarioId,
    string Nombre,
    string Email,
    string? Telefono,
    string EstadoDisponibilidad,
    string? Vehiculo,
    int EntregasCompletadas,
    DateTime FechaAlta);

public sealed record AdminDeliveryHistoryItem(
    string NumeroPedido,
    string Cliente,
    decimal Total,
    DateTime? EntregadoEn,
    double? TiempoEntregaMinutos);

public sealed record DeliveryUserCandidate(Guid UsuarioId, string Nombre, string Email);

public static class DeliveryStatusUi
{
    public static IReadOnlyList<string> All { get; } = new[] { "disponible", "ocupado", "inactivo" };

    public static string Display(string estado) => estado.ToLowerInvariant() switch
    {
        "disponible" => "Disponible",
        "ocupado" => "Ocupado",
        "inactivo" => "Inactivo",
        _ => estado,
    };

    public static Color Color(string estado) => estado.ToLowerInvariant() switch
    {
        "disponible" => MudBlazor.Color.Success,
        "ocupado" => MudBlazor.Color.Warning,
        "inactivo" => MudBlazor.Color.Default,
        _ => MudBlazor.Color.Default,
    };
}