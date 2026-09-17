using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class OrderRepository : IOrderRepository
{
    private readonly QuickBiteDbContext _db;

    public OrderRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(Order order, CancellationToken cancellationToken = default)
    {
        await _db.Pedidos.AddAsync(order, cancellationToken);
    }

    public async Task<Order?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _db.Pedidos
            .Include(p => p.Items)
                .ThenInclude(i => i.Opciones)
            .Include(p => p.Items)
                .ThenInclude(i => i.Producto)
            .Include(p => p.HistorialEstados)
            .Include(p => p.Cliente)
            .Include(p => p.Direccion)
            .Include(p => p.Repartidor)
                .ThenInclude(r => r!.Usuario)
            .Include(p => p.MetodoPagoCatalogo)
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
    }

    public async Task<Order?> GetByOrderNumberAsync(string orderNumber, CancellationToken cancellationToken = default)
    {
        return await _db.Pedidos
            .Include(p => p.Items)
            .Include(p => p.HistorialEstados)
            .FirstOrDefaultAsync(p => p.NumeroPedido == orderNumber, cancellationToken);
    }

    public async Task<IReadOnlyList<Order>> GetOrdersAsync(Guid? clientId = null, Guid? deliveryPersonId = null, OrderStatus? status = null, CancellationToken cancellationToken = default)
    {
        var query = _db.Pedidos
            .AsNoTracking()
            .Include(p => p.Cliente)
            .AsQueryable();

        if (clientId.HasValue)
        {
            query = query.Where(p => p.ClienteId == clientId.Value);
        }

        if (deliveryPersonId.HasValue)
        {
            query = query.Where(p => p.RepartidorId == deliveryPersonId.Value);
        }

        if (status.HasValue)
        {
            query = query.Where(p => p.Estado == status.Value);
        }

        return await query
            .OrderByDescending(p => p.CreadoEn)
            .ToListAsync(cancellationToken);
    }

    public async Task UpdateStatusAsync(Guid orderId, OrderStatus newStatus, string? comment = null, Guid? userId = null, CancellationToken cancellationToken = default)
    {
        var order = await _db.Pedidos.FirstOrDefaultAsync(p => p.Id == orderId, cancellationToken);
        if (order is null)
        {
            return;
        }

        var previous = order.Estado;
        order.Estado = newStatus;
        AplicarMarcaTemporal(order, newStatus);
        order.ActualizadoEn = DateTime.UtcNow;

        _db.PedidoHistorialEstados.Add(new OrderStatusHistory
        {
            PedidoId = order.Id,
            EstadoAnterior = previous,
            EstadoNuevo = newStatus,
            UsuarioId = userId,
            Comentario = comment
        });
    }

    public async Task AssignDeliveryPersonAsync(Guid orderId, Guid deliveryPersonId, AssignmentOrigin origin, CancellationToken cancellationToken = default)
    {
        var order = await _db.Pedidos.FindAsync(new object[] { orderId }, cancellationToken);
        if (order is null)
        {
            return;
        }

        order.RepartidorId = deliveryPersonId;
        order.ActualizadoEn = DateTime.UtcNow;

        var deliveryPerson = await _db.Repartidores.FindAsync(new object[] { deliveryPersonId }, cancellationToken);
        if (deliveryPerson is not null)
        {
            deliveryPerson.EstadoDisponibilidad = DeliveryPersonStatus.Ocupado;
        }
    }

    public async Task CancelOrderAsync(Guid orderId, string reason, Guid? userId = null, CancellationToken cancellationToken = default)
    {
        var order = await _db.Pedidos.FindAsync(new object[] { orderId }, cancellationToken);
        if (order is null || order.Estado == OrderStatus.Cancelado)
        {
            return;
        }

        var previous = order.Estado;
        order.Estado = OrderStatus.Cancelado;
        order.MotivoCancelacion = reason;
        AplicarMarcaTemporal(order, OrderStatus.Cancelado);
        order.ActualizadoEn = DateTime.UtcNow;

        _db.PedidoHistorialEstados.Add(new OrderStatusHistory
        {
            PedidoId = order.Id,
            EstadoAnterior = previous,
            EstadoNuevo = OrderStatus.Cancelado,
            UsuarioId = userId,
            Comentario = reason
        });
    }

    private static void AplicarMarcaTemporal(Order order, OrderStatus status)
    {
        var now = DateTime.UtcNow;
        switch (status)
        {
            case OrderStatus.Confirmado:
                order.ConfirmadoEn ??= now;
                break;
            case OrderStatus.Preparando:
                order.PreparandoEn ??= now;
                break;
            case OrderStatus.Listo:
                order.ListoEn ??= now;
                break;
            case OrderStatus.EnCamino:
                order.EnCaminoEn ??= now;
                break;
            case OrderStatus.Entregado:
                order.EntregadoEn ??= now;
                break;
            case OrderStatus.Cancelado:
                order.CanceladoEn ??= now;
                break;
        }
    }
}