using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Catalog.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;

namespace QuickBite.Application.Admin;

public sealed class AdminDeliveryService : IAdminDeliveryService
{
    private readonly IUnitOfWork _uow;

    public AdminDeliveryService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    private static DeliveryPersonListItemResponse ToItem(DeliveryPerson r) => new(
        r.UsuarioId,
        r.Usuario?.Nombre ?? string.Empty,
        r.Usuario?.Email ?? string.Empty,
        r.Usuario?.Telefono,
        r.EstadoDisponibilidad.ToString().ToLowerInvariant(),
        r.Vehiculo,
        r.EntregasCompletadas,
        r.FechaAlta);

    public async Task<PagedResponse<DeliveryPersonListItemResponse>> ListAsync(string? estado, int page, int limit, CancellationToken ct = default)
    {
        DeliveryPersonStatus? status = null;
        if (!string.IsNullOrWhiteSpace(estado))
        {
            if (!Enum.TryParse<DeliveryPersonStatus>(estado, ignoreCase: true, out var parsed))
                throw new ValidationException("estado", "estado_disponibilidad inválido. Valores: disponible, ocupado, inactivo");
            status = parsed;
        }

        var (items, total) = await _uow.DeliveryPeople.GetPagedAsync(status, page, limit, ct);
        var data = items.Select(ToItem).ToList();
        var totalPages = (int)Math.Ceiling((double)total / Math.Max(1, limit));
        return new PagedResponse<DeliveryPersonListItemResponse>(data, total, Math.Max(1, page), limit, totalPages);
    }

    public async Task<DeliveryPersonListItemResponse> CreateAsync(CreateDeliveryPersonRequest req, CancellationToken ct = default)
    {
        var user = await _uow.Users.GetByIdAsync(req.UsuarioId, ct)
            ?? throw new ValidationException("usuario_id", "El usuario no existe");
        if (user.Rol != UserRole.Repartidor)
            throw new ValidationException("usuario_id", "El usuario no tiene rol repartidor");

        if (await _uow.DeliveryPeople.GetByIdAsync(req.UsuarioId, ct) != null)
            throw new ConflictException("El usuario ya está registrado como repartidor");

        var deliveryPerson = new DeliveryPerson
        {
            UsuarioId = req.UsuarioId,
            Vehiculo = string.IsNullOrWhiteSpace(req.Vehiculo) ? null : req.Vehiculo.Trim(),
            EstadoDisponibilidad = DeliveryPersonStatus.Inactivo
        };

        await _uow.DeliveryPeople.AddAsync(deliveryPerson, ct);
        await _uow.SaveChangesAsync(ct);
        return ToItem(deliveryPerson);
    }

    public async Task<DeliveryPersonListItemResponse> UpdateAsync(Guid id, UpdateDeliveryPersonRequest req, CancellationToken ct = default)
    {
        var deliveryPerson = await _uow.DeliveryPeople.GetByIdAsync(id, ct)
            ?? throw new NotFoundException("Repartidor", id);

        if (!string.IsNullOrWhiteSpace(req.EstadoDisponibilidad))
        {
            if (!Enum.TryParse<DeliveryPersonStatus>(req.EstadoDisponibilidad, ignoreCase: true, out var estado))
                throw new ValidationException("estado_disponibilidad", "Valores válidos: disponible, ocupado, inactivo");

            if (estado == DeliveryPersonStatus.Disponible && await _uow.Orders.HasActiveOrdersAsync(id, ct))
                throw new BusinessRuleException("No se puede marcar como disponible si tiene pedidos activos");

            deliveryPerson.EstadoDisponibilidad = estado;
        }

        if (req.Vehiculo != null)
            deliveryPerson.Vehiculo = string.IsNullOrWhiteSpace(req.Vehiculo) ? null : req.Vehiculo.Trim();

        _uow.DeliveryPeople.Update(deliveryPerson);
        await _uow.SaveChangesAsync(ct);
        return ToItem(deliveryPerson);
    }

    public async Task<DeliveryPersonListItemResponse> DeactivateAsync(Guid id, CancellationToken ct = default)
    {
        var deliveryPerson = await _uow.DeliveryPeople.GetByIdAsync(id, ct)
            ?? throw new NotFoundException("Repartidor", id);

        if (await _uow.Orders.HasActiveOrdersAsync(id, ct))
            throw new BusinessRuleException("No se puede desactivar con pedidos activos");

        deliveryPerson.EstadoDisponibilidad = DeliveryPersonStatus.Inactivo;
        _uow.DeliveryPeople.Update(deliveryPerson);
        await _uow.SaveChangesAsync(ct);
        return ToItem(deliveryPerson);
    }

    public async Task<PagedResponse<DeliveryPersonHistoryResponse>> GetHistoryAsync(Guid id, int page, int limit, CancellationToken ct = default)
    {
        if (await _uow.DeliveryPeople.GetByIdAsync(id, ct) == null)
            throw new NotFoundException("Repartidor", id);

        var (items, total) = await _uow.Orders.GetDeliveredByDeliveryPersonPagedAsync(id, page, limit, ct);
        var data = items.Select(o => new DeliveryPersonHistoryResponse(
            o.NumeroPedido,
            o.Cliente?.Nombre ?? string.Empty,
            o.Total,
            o.EntregadoEn,
            o.EnCaminoEn != null && o.EntregadoEn != null ? (o.EntregadoEn - o.EnCaminoEn)?.TotalMinutes : null)).ToList();
        var totalPages = (int)Math.Ceiling((double)total / Math.Max(1, limit));
        return new PagedResponse<DeliveryPersonHistoryResponse>(data, total, Math.Max(1, page), limit, totalPages);
    }

    public async Task<IReadOnlyList<DeliveryUserCandidateResponse>> GetAvailableUsersAsync(CancellationToken ct = default)
    {
        var users = await _uow.Users.GetByRoleAsync(UserRole.Repartidor, ct);
        var (existing, _) = await _uow.DeliveryPeople.GetPagedAsync(null, 1, 1000, ct);
        var existingIds = existing.Select(d => d.UsuarioId).ToHashSet();

        return users
            .Where(u => !existingIds.Contains(u.Id))
            .Select(u => new DeliveryUserCandidateResponse(u.Id, u.Nombre, u.Email))
            .ToList();
    }
}