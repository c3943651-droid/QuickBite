namespace QuickBite.Application.Admin.Dtos;

public sealed record CreateDeliveryPersonRequest { public Guid UsuarioId { get; init; } public string? Vehiculo { get; init; } }
public sealed record UpdateDeliveryPersonRequest { public string? Vehiculo { get; init; } public string? EstadoDisponibilidad { get; init; } }
public sealed record DeliveryPersonListItemResponse(Guid UsuarioId, string Nombre, string Email, string? Telefono, string EstadoDisponibilidad, string? Vehiculo, int EntregasCompletadas, DateTime FechaAlta);
public sealed record DeliveryPersonHistoryResponse(string NumeroPedido, string Cliente, decimal Total, DateTime? EntregadoEn, double? TiempoEntregaMinutos);