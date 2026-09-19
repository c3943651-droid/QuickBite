namespace QuickBite.Application.Admin.Dtos;

public sealed record AdminOrderListItemResponse(
    Guid Id,
    string NumeroPedido,
    string Cliente,
    string Estado,
    decimal Total,
    DateTime CreadoEn,
    string? Repartidor);

public sealed record AdminOrderItemOptionResponse(string Nombre, decimal PrecioAdicional);

public sealed record AdminOrderItemResponse(
    Guid Id,
    string NombreProducto,
    decimal PrecioUnitario,
    short Cantidad,
    string? Observaciones,
    decimal Subtotal,
    IReadOnlyList<AdminOrderItemOptionResponse> Opciones);

public sealed record AdminOrderStatusHistoryResponse(
    Guid Id,
    string? EstadoAnterior,
    string EstadoNuevo,
    string? Usuario,
    string? Comentario,
    DateTime CreadoEn);

public sealed record AdminOrderAuditResponse(
    Guid Id,
    string Accion,
    string? Usuario,
    string? IpOrigen,
    DateTime CreadoEn,
    string? Detalles);

public sealed record AdminOrderDetailResponse(
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
    IReadOnlyList<AdminOrderItemResponse> Items,
    IReadOnlyList<AdminOrderStatusHistoryResponse> HistorialEstados,
    IReadOnlyList<AdminOrderAuditResponse> Auditoria);