using QuickBite.Application.Orders.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Rules;
namespace QuickBite.Application.Orders;
public sealed class OrderService : IOrderService
{
    private readonly IUnitOfWork _uow;
    public OrderService(IUnitOfWork uow) { _uow = uow; }
    public async Task<OrderResponse> CreateAsync(Guid userId, CreateOrderRequest req, CancellationToken ct = default)
    {
        var cart = await _uow.Carts.GetActiveByUserIdAsync(userId, ct) ?? throw new BusinessRuleException("Carrito vacio");
        if (!cart.Items.Any()) throw new BusinessRuleException("Carrito vacio");
        var order = new Order { ClienteId = userId, DireccionId = req.DireccionId, DireccionEntregaSnapshot = req.DireccionSnapshot ?? "", MetodoPago = ParseMetodoPago(req.MetodoPago), NumeroPedido = $"QB-{DateTime.UtcNow:yyyyMMdd}-{Guid.NewGuid().ToString()[..6].ToUpper()}", Estado = OrderStatus.Pendiente };
        foreach (var ci in cart.Items)
        {
            var unitPrice = ci.Producto?.Precio ?? 0m;
            var item = new OrderItem
            {
                ProductoId = ci.ProductoId,
                NombreProducto = ci.Producto?.Nombre ?? string.Empty,
                Cantidad = ci.Cantidad,
                PrecioUnitario = unitPrice,
                Subtotal = OrderCalculationRules.CalculateOrderItemSubtotal(unitPrice, ci.Cantidad, ci.Opciones.Select(o => o.Opcion?.PrecioAdicional ?? 0m))
            };
            foreach (var opcion in ci.Opciones.Where(o => o.Opcion is not null))
            {
                item.Opciones.Add(new OrderItemOption
                {
                    NombreOpcion = opcion.Opcion!.Nombre,
                    PrecioAdicional = opcion.Opcion.PrecioAdicional
                });
            }
            order.Items.Add(item);
        }
        order.Subtotal = OrderCalculationRules.CalculateOrderSubtotal(order.Items);
        order.Total = OrderCalculationRules.CalculateOrderTotal(order.Subtotal, order.CostoEnvio);
        await _uow.Orders.AddAsync(order, ct);
        await _uow.Carts.ClearCartAsync(cart.Id, ct);
        await _uow.SaveChangesAsync(ct);
        return new OrderResponse(order.Id, order.NumeroPedido, order.Estado.ToString(), order.Total, order.CreadoEn);
    }
    public async Task<IReadOnlyList<OrderResponse>> ListAsync(Guid userId, CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetOrdersAsync(userId, null, null, ct);
        return orders.Select(o => new OrderResponse(o.Id, o.NumeroPedido, o.Estado.ToString(), o.Total, o.CreadoEn)).ToList();
    }
    public async Task<OrderDetailResponse> GetAsync(Guid userId, Guid orderId, CancellationToken ct = default)
    {
        var o = await _uow.Orders.GetByIdAsync(orderId, ct) ?? throw new NotFoundException("Pedido", orderId);
        if (o.ClienteId != userId) throw new ForbiddenException();
        return new OrderDetailResponse(o.Id, o.NumeroPedido, o.Estado.ToString(), o.Subtotal, o.CostoEnvio, o.Total, o.Items.Select(i => i.Producto?.Nombre ?? "").ToList());
    }
    public async Task<OrderStatusResponse> GetStatusAsync(Guid userId, Guid orderId, CancellationToken ct = default)
    {
        var o = await _uow.Orders.GetByIdAsync(orderId, ct) ?? throw new NotFoundException("Pedido", orderId);
        if (o.ClienteId != userId) throw new ForbiddenException();
        return new OrderStatusResponse(o.Id, o.Estado.ToString(), o.ActualizadoEn);
    }
    public async Task CancelAsync(Guid userId, Guid orderId, string motivo, CancellationToken ct = default)
    {
        var o = await _uow.Orders.GetByIdAsync(orderId, ct) ?? throw new NotFoundException("Pedido", orderId);
        if (o.ClienteId != userId) throw new ForbiddenException();
        await _uow.Orders.CancelOrderAsync(orderId, motivo, userId, ct);
        await _uow.SaveChangesAsync(ct);
    }

    private static PaymentMethodType ParseMetodoPago(string? metodoPago)
    {
        return metodoPago?.Trim().ToLowerInvariant() switch
        {
            "tarjeta" => PaymentMethodType.Tarjeta,
            "efectivo" => PaymentMethodType.Efectivo,
            _ => throw new ValidationException("metodoPago", "El método de pago debe ser 'efectivo' o 'tarjeta'.")
        };
    }
}
