namespace QuickBite.Application.Orders.Dtos;
public sealed record CreateOrderRequest { public Guid? DireccionId { get; init; } public string? DireccionSnapshot { get; init; } public string MetodoPago { get; init; } = "efectivo"; }
public sealed record OrderResponse(Guid Id, string NumeroPedido, string Estado, decimal Total, DateTime CreadoEn);
public sealed record OrderDetailResponse(Guid Id, string NumeroPedido, string Estado, decimal Subtotal, decimal CostoEnvio, decimal Total, IReadOnlyList<string> Items);
public sealed record OrderStatusResponse(Guid Id, string Estado, DateTime ActualizadoEn);
