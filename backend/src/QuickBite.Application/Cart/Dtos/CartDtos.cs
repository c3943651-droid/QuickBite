namespace QuickBite.Application.Cart.Dtos;
public sealed record AddCartItemRequest { public Guid ProductoId { get; init; } public short Cantidad { get; init; } = 1; public string? Observaciones { get; init; } public List<Guid> OpcionesIds { get; init; } = []; }
public sealed record UpdateCartItemRequest { public short Cantidad { get; init; } public string? Observaciones { get; init; } }
public sealed record CartItemResponse(Guid Id, Guid ProductoId, string Nombre, decimal Precio, short Cantidad, IReadOnlyList<string> Opciones, decimal Subtotal);
public sealed record CartResponse(Guid Id, IReadOnlyList<CartItemResponse> Items, decimal Total);
