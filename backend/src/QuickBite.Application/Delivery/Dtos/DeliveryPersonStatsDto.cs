namespace QuickBite.Application.Delivery.Dtos;

public sealed record DeliveryPersonStatsDto(
    Guid DeliveryPersonId,
    int EntregasTotales,
    int EntregasDelMes,
    double TiempoPromedioEntregaMinutos,
    int PedidosAsignadosActivos,
    int Cancelaciones);