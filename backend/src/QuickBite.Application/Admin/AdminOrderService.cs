using QuickBite.Application.Admin;
using QuickBite.Application.Orders.Dtos;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
namespace QuickBite.Application.Admin;
public sealed class AdminOrderService : IAdminOrderService
{
    private readonly IUnitOfWork _uow;
    public AdminOrderService(IUnitOfWork uow) { _uow = uow; }
    public async Task<IReadOnlyList<OrderResponse>> ListAsync(OrderStatus? status, Guid? repartidorId, CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetOrdersAsync(null, repartidorId, status, ct);
        return orders.Select(o => new OrderResponse(o.Id, o.NumeroPedido, o.Estado.ToString(), o.Total, o.CreadoEn)).ToList();
    }
    public async Task<OrderResponse> UpdateStatusAsync(Guid orderId, OrderStatus status, CancellationToken ct = default)
    {
        await _uow.Orders.UpdateStatusAsync(orderId, status, null, null, ct);
        await _uow.SaveChangesAsync(ct);
        var o = await _uow.Orders.GetByIdAsync(orderId, ct);
        return new OrderResponse(o!.Id, o.NumeroPedido, o.Estado.ToString(), o.Total, o.CreadoEn);
    }
    public async Task CancelAsync(Guid orderId, string motivo, CancellationToken ct = default) { await _uow.Orders.CancelOrderAsync(orderId, motivo, null, ct); await _uow.SaveChangesAsync(ct); }
    public async Task AssignAsync(Guid orderId, Guid repartidorId, AssignmentOrigin origin, CancellationToken ct = default) { await _uow.Orders.AssignDeliveryPersonAsync(orderId, repartidorId, origin, ct); await _uow.SaveChangesAsync(ct); }
    public async Task<object> DashboardAsync(CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetOrdersAsync(null, null, null, ct);
        var total = orders.Count; var ventas = orders.Sum(o => o.Total);
        var pendientes = orders.Count(o => o.Estado == OrderStatus.Pendiente);
        return new { totalPedidos = total, ventasTotales = ventas, pendientes, porEstado = orders.GroupBy(o => o.Estado.ToString()).ToDictionary(g => g.Key, g => g.Count()) };
    }
}
