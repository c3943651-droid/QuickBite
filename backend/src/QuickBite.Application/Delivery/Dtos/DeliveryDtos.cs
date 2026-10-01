namespace QuickBite.Application.Delivery.Dtos;

public sealed record SetAvailabilityRequest { public int Estado { get; init; } }

/// Pedido visto desde el repartidor.
///
/// Antes el repartidor recibía el mismo `OrderResponse` que el cliente: número,
/// estado, total y coordenadas. Con eso no podía saber a quién entregar ni qué
/// llevar, así que se añadió lo mínimo que necesita para trabajar el pedido.
/// Todos los campos nuevos son opcionales para no romper clientes ya desplegados.
public sealed record DeliveryOrderResponse(
    Guid Id,
    string NumeroPedido,
    string Estado,
    decimal Subtotal,
    decimal CostoEnvio,
    decimal Total,
    IReadOnlyList<string> Items,
    decimal? Latitud,
    decimal? Longitud,
    DateTime CreadoEn,
    string? Cliente = null,
    string? Direccion = null,
    string? Telefono = null);
