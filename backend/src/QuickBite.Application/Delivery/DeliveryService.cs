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
    public async Task<IReadOnlyList<DeliveryOrderResponse>> AvailableAsync(Guid repartidorId, CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetDeliveryOrdersAsync(null, OrderStatus.Listo, ct);
        return orders.Where(o => o.RepartidorId == null).Select(ToResponse).ToList();
    }
    public async Task AcceptAsync(Guid repartidorId, Guid orderId, CancellationToken ct = default)
    {
        var o = await _uow.Orders.GetByIdAsync(orderId, ct) ?? throw new NotFoundException("Pedido", orderId);
        if (o.Estado != OrderStatus.Listo) throw new BusinessRuleException("Solo pedidos Listo pueden ser aceptados");
        if (o.RepartidorId != null) throw new ConflictException("Pedido ya asignado");
        await _uow.Orders.AssignDeliveryPersonAsync(orderId, repartidorId, AssignmentOrigin.Auto, ct);
        // Se guarda antes del cambio de estado por trg_validar_asignacion_repartidor,
        // que solo admite cambiar repartidor_id con el pedido en 'listo'.
        await _uow.SaveChangesAsync(ct);
        await _uow.Orders.UpdateStatusAsync(orderId, OrderStatus.EnCamino, null, repartidorId, ct);
        await _uow.SaveChangesAsync(ct);
    }
    public async Task<IReadOnlyList<DeliveryOrderResponse>> ActiveAsync(Guid repartidorId, CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetDeliveryOrdersAsync(repartidorId, OrderStatus.EnCamino, ct);
        return orders.Select(ToResponse).ToList();
    }
    public async Task CompleteAsync(Guid repartidorId, Guid orderId, CancellationToken ct = default)
    {
        var o = await _uow.Orders.GetByIdAsync(orderId, ct) ?? throw new NotFoundException("Pedido", orderId);
        if (o.RepartidorId != repartidorId) throw new ForbiddenException();
        await _uow.Orders.UpdateStatusAsync(orderId, OrderStatus.Entregado, null, repartidorId, ct);
        await _uow.SaveChangesAsync(ct);
    }
    public async Task<IReadOnlyList<DeliveryOrderResponse>> HistoryAsync(Guid repartidorId, CancellationToken ct = default)
    {
        var orders = await _uow.Orders.GetDeliveryOrdersAsync(repartidorId, null, ct);
        return orders
            .Where(o => o.Estado == OrderStatus.Entregado || o.Estado == OrderStatus.Cancelado)
            .Select(ToResponse)
            .ToList();
    }

    /// Proyecta al DTO del repartidor. La dirección prefiere el snapshot que se
    /// guardó al crear el pedido (es lo que el cliente confirmó) y cae a la
    /// dirección viva si el snapshot viniera vacío.
    private static DeliveryOrderResponse ToResponse(Domain.Entities.Order o) => new(
        o.Id,
        o.NumeroPedido,
        o.Estado.ToString(),
        o.Subtotal,
        o.CostoEnvio,
        o.Total,
        o.Items.Select(i => i.Producto?.Nombre ?? "").Where(n => !string.IsNullOrEmpty(n)).ToList(),
        o.Latitud,
        o.Longitud,
        o.CreadoEn,
        o.Cliente?.Nombre,
        string.IsNullOrWhiteSpace(o.DireccionEntregaSnapshot) ? DireccionDe(o) : o.DireccionEntregaSnapshot,
        o.Cliente?.Telefono);

    private static string? DireccionDe(Domain.Entities.Order o)
    {
        var d = o.Direccion;
        if (d is null) return null;
        var calle = string.IsNullOrWhiteSpace(d.Calle) ? null : $"{d.Calle} {d.Numero}".Trim();
        var partes = new[] { calle, d.Ciudad }
            .Where(p => !string.IsNullOrWhiteSpace(p))
            .ToArray();
        return partes.Length == 0 ? null : string.Join(", ", partes);
    }
    public async Task<DeliveryAvailabilityDto> SetAvailabilityAsync(Guid repartidorId, DeliveryPersonStatus estado, CancellationToken ct = default)
    {
        if (!Enum.IsDefined(estado)) throw new BusinessRuleException($"Estado de disponibilidad inválido: {estado}");
        var repartidor = await _uow.DeliveryPeople.GetByIdAsync(repartidorId, ct)
            ?? throw new NotFoundException("Repartidor", repartidorId);

        var activos = await _uow.Orders.GetOrdersAsync(null, repartidorId, OrderStatus.EnCamino, ct);
        var tieneEntregaActiva = activos.Count > 0;

        if (repartidor.EstadoDisponibilidad == estado)
            return DeliveryAvailabilityDto.From(tieneEntregaActiva, repartidor.EstadoDisponibilidad);

        if (estado == DeliveryPersonStatus.Disponible && tieneEntregaActiva)
            throw new BusinessRuleException("No puedes marcarte disponible con una entrega en camino");

        repartidor.EstadoDisponibilidad = estado;
        _uow.DeliveryPeople.Update(repartidor);
        await _uow.SaveChangesAsync(ct);

        return DeliveryAvailabilityDto.From(tieneEntregaActiva, repartidor.EstadoDisponibilidad);
    }
    public async Task<DeliveryPersonStatsDto> StatsAsync(Guid repartidorId, CancellationToken ct = default)
    {
        var stats = await _uow.DeliveryPeople.GetStatsAsync(repartidorId, ct);
        if (stats == null) return new DeliveryPersonStatsDto(repartidorId, 0, 0, 0, 0, 0);
        return new DeliveryPersonStatsDto(stats.DeliveryPersonId, stats.EntregasTotales, stats.EntregasDelMes, stats.TiempoPromedioEntregaMinutos, stats.PedidosAsignadosActivos, stats.Cancelaciones);
    }
}
