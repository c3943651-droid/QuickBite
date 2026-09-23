using QuickBite.Application.Delivery;
using QuickBite.Application.Delivery.Dtos;
using QuickBite.Application.Orders.Dtos;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;
namespace QuickBite.Application.Delivery;
public sealed class DeliveryService : IDeliveryService
{
    private readonly IUnitOfWork _uow;
    public DeliveryService(IUnitOfWork uow) { _uow = uow; }
    public async Task<IReadOnlyList<OrderResponse>> AvailableAsync(Guid repartidorId, CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetOrdersAsync(null, null, OrderStatus.Listo, ct);
        var avail = orders.Where(o => o.RepartidorId == null).Select(o => new OrderResponse(o.Id, o.NumeroPedido, o.Estado.ToString(), o.Total, o.CreadoEn)).ToList();
        return avail;
    }
    public async Task AcceptAsync(Guid repartidorId, Guid orderId, CancellationToken ct = default)
    {
        var o = await _uow.Orders.GetByIdAsync(orderId, ct) ?? throw new NotFoundException("Pedido", orderId);
        if (o.Estado != OrderStatus.Listo) throw new BusinessRuleException("Solo pedidos Listo pueden ser aceptados");
        if (o.RepartidorId != null) throw new ConflictException("Pedido ya asignado");
        await _uow.Orders.AssignDeliveryPersonAsync(orderId, repartidorId, AssignmentOrigin.Auto, ct);
        await _uow.Orders.UpdateStatusAsync(orderId, OrderStatus.EnCamino, null, repartidorId, ct);
        await _uow.SaveChangesAsync(ct);
    }
    public async Task<IReadOnlyList<OrderResponse>> ActiveAsync(Guid repartidorId, CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetOrdersAsync(null, repartidorId, OrderStatus.EnCamino, ct);
        return orders.Select(o => new OrderResponse(o.Id, o.NumeroPedido, o.Estado.ToString(), o.Total, o.CreadoEn)).ToList();
    }
    public async Task CompleteAsync(Guid repartidorId, Guid orderId, CancellationToken ct = default)
    {
        var o = await _uow.Orders.GetByIdAsync(orderId, ct) ?? throw new NotFoundException("Pedido", orderId);
        if (o.RepartidorId != repartidorId) throw new ForbiddenException();
        await _uow.Orders.UpdateStatusAsync(orderId, OrderStatus.Entregado, null, repartidorId, ct);
        await _uow.SaveChangesAsync(ct);
    }
    public async Task<IReadOnlyList<OrderResponse>> HistoryAsync(Guid repartidorId, CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetOrdersAsync(null, repartidorId, null, ct);
        var hist = orders.Where(o => o.Estado == OrderStatus.Entregado || o.Estado == OrderStatus.Cancelado).Select(o => new OrderResponse(o.Id, o.NumeroPedido, o.Estado.ToString(), o.Total, o.CreadoEn)).ToList();
        return hist;
    }
    public async Task<DeliveryPersonStatsDto> StatsAsync(Guid repartidorId, CancellationToken ct = default)
    {
        var stats = await _uow.DeliveryPeople.GetStatsAsync(repartidorId, ct);
        if (stats == null) return new DeliveryPersonStatsDto(repartidorId, 0, 0, 0, 0, 0);
        return new DeliveryPersonStatsDto(stats.DeliveryPersonId, stats.EntregasTotales, stats.EntregasDelMes, stats.TiempoPromedioEntregaMinutos, stats.PedidosAsignadosActivos, stats.Cancelaciones);
    }
}
