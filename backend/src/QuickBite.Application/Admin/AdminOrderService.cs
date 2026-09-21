using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Catalog.Dtos;
using QuickBite.Application.Orders.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Shared.Dashboard;
namespace QuickBite.Application.Admin;
public sealed class AdminOrderService : IAdminOrderService
{
    private readonly IUnitOfWork _uow;
    public AdminOrderService(IUnitOfWork uow) { _uow = uow; }

    private static AdminOrderListItemResponse ToListItem(Order o) => new(
        o.Id,
        o.NumeroPedido,
        o.Cliente?.Nombre ?? string.Empty,
        o.Estado.ToString(),
        o.Total,
        o.CreadoEn,
        o.Repartidor?.Usuario?.Nombre);

    private static AdminOrderItemResponse ToItem(OrderItem item) => new(
        item.Id,
        item.NombreProducto,
        item.PrecioUnitario,
        item.Cantidad,
        item.Observaciones,
        item.Subtotal,
        item.Opciones.Select(op => new AdminOrderItemOptionResponse(op.NombreOpcion, op.PrecioAdicional)).ToList());

    private static AdminOrderStatusHistoryResponse ToHistory(OrderStatusHistory h) => new(
        h.Id,
        h.EstadoAnterior?.ToString(),
        h.EstadoNuevo.ToString(),
        h.Usuario?.Nombre,
        h.Comentario,
        h.CreadoEn);

    private static AdminOrderAuditResponse ToAudit(AuditAction a) => new(
        a.Id,
        a.Accion,
        a.Usuario?.Nombre,
        a.IpOrigen,
        a.CreadoEn,
        a.Detalles);

    public async Task<PagedResponse<AdminOrderListItemResponse>> ListAsync(string? search, OrderStatus? status, Guid? repartidorId, DateTime? fechaDesde, DateTime? fechaHasta, int page, int limit, CancellationToken ct = default)
    {
        var (items, total) = await _uow.Orders.GetOrdersForAdminAsync(search, repartidorId, status, fechaDesde, fechaHasta, page, limit, ct);
        var totalPages = (int)Math.Ceiling(total / (double)Math.Max(1, limit));
        return new PagedResponse<AdminOrderListItemResponse>(items.Select(ToListItem).ToList(), total, Math.Max(1, page), limit, totalPages);
    }

    public async Task<AdminOrderDetailResponse?> GetAsync(Guid orderId, CancellationToken ct = default)
    {
        var o = await _uow.Orders.GetByIdAsync(orderId, ct);
        if (o is null) return null;

        var auditoria = await _uow.Audits.GetFilteredAsync(entityId: orderId, cancellationToken: ct);
        return new AdminOrderDetailResponse(
            o.Id,
            o.NumeroPedido,
            o.Estado.ToString(),
            o.CreadoEn,
            o.MotivoCancelacion,
            o.Cliente?.Nombre ?? string.Empty,
            o.Cliente?.Email,
            o.Cliente?.Telefono,
            o.DireccionEntregaSnapshot,
            o.Repartidor?.Usuario?.Nombre,
            o.Repartidor?.Usuario?.Telefono,
            o.Repartidor?.EstadoDisponibilidad.ToString().ToLowerInvariant(),
            o.Subtotal,
            o.CostoEnvio,
            o.Total,
            o.Items.Select(ToItem).ToList(),
            o.HistorialEstados.OrderBy(h => h.CreadoEn).Select(ToHistory).ToList(),
            auditoria.Select(ToAudit).ToList());
    }

    public async Task<OrderResponse> UpdateStatusAsync(Guid orderId, OrderStatus status, string? comentario = null, CancellationToken ct = default)
    {
        await _uow.Orders.UpdateStatusAsync(orderId, status, comentario, null, ct);
        await _uow.SaveChangesAsync(ct);
        var o = await _uow.Orders.GetByIdAsync(orderId, ct);
        return new OrderResponse(o!.Id, o.NumeroPedido, o.Estado.ToString(), o.Total, o.CreadoEn);
    }
    public async Task CancelAsync(Guid orderId, string motivo, CancellationToken ct = default) { await _uow.Orders.CancelOrderAsync(orderId, motivo, null, ct); await _uow.SaveChangesAsync(ct); }
    public async Task AssignAsync(Guid orderId, Guid repartidorId, AssignmentOrigin origin, CancellationToken ct = default) { await _uow.Orders.AssignDeliveryPersonAsync(orderId, repartidorId, origin, ct); await _uow.SaveChangesAsync(ct); }
    public async Task<DashboardDataDto> DashboardAsync(CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetOrdersAsync(null, null, null, ct);

        var today = DateTime.UtcNow.Date;
        var firstDay = today.AddDays(-6);
        var salesChart = Enumerable.Range(0, 7)
            .Select(i => firstDay.AddDays(i))
            .Select(day => new SalesChartItemDto
            {
                Dia = day.ToString("yyyy-MM-dd"),
                Ventas = orders.Where(o => o.CreadoEn.Date == day).Sum(o => o.Total)
            })
            .ToList();

        var recentOrders = orders
            .OrderByDescending(o => o.CreadoEn)
            .Take(5)
            .Select(o => new RecentOrderDto
            {
                Id = o.Id,
                NumeroPedido = o.NumeroPedido,
                Cliente = o.Cliente?.Nombre ?? string.Empty,
                Estado = o.Estado.ToString(),
                Total = o.Total,
                Fecha = o.CreadoEn
            })
            .ToList();

        return new DashboardDataDto
        {
            TotalPedidos = orders.Count,
            VentasTotales = orders.Sum(o => o.Total),
            Pendientes = orders.Count(o => o.Estado == OrderStatus.Pendiente),
            PorEstado = orders.GroupBy(o => o.Estado.ToString()).ToDictionary(g => g.Key, g => g.Count()),
            SalesChart = salesChart,
            RecentOrders = recentOrders
        };
    }
}