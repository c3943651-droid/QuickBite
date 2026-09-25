using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class DeliveryPersonRepository : IDeliveryPersonRepository
{
    private readonly QuickBiteDbContext _db;

    public DeliveryPersonRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<DeliveryPerson>> GetByStatusAsync(DeliveryPersonStatus status, CancellationToken cancellationToken = default)
    {
        return await _db.Repartidores
            .AsNoTracking()
            .Include(r => r.Usuario)
            .Where(r => r.EstadoDisponibilidad == status)
            .OrderBy(r => r.FechaAlta)
            .ToListAsync(cancellationToken);
    }

    public async Task<DeliveryPerson?> GetByIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _db.Repartidores
            .AsNoTracking()
            .Include(r => r.Usuario)
            .FirstOrDefaultAsync(r => r.UsuarioId == userId, cancellationToken);
    }

    public async Task<(IReadOnlyList<DeliveryPerson> Items, int TotalCount)> GetPagedAsync(DeliveryPersonStatus? status, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        IQueryable<DeliveryPerson> query = _db.Repartidores
            .AsNoTracking()
            .Include(r => r.Usuario);

        if (status.HasValue)
        {
            query = query.Where(r => r.EstadoDisponibilidad == status.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderBy(r => r.FechaAlta)
            .Skip((Math.Max(1, page) - 1) * Math.Clamp(pageSize, 1, 100))
            .Take(Math.Clamp(pageSize, 1, 100))
            .ToListAsync(cancellationToken);

        return (items, totalCount);
    }

    public async Task AddAsync(DeliveryPerson deliveryPerson, CancellationToken cancellationToken = default)
    {
        await _db.Repartidores.AddAsync(deliveryPerson, cancellationToken);
    }

    public void Update(DeliveryPerson deliveryPerson)
    {
        _db.Repartidores.Update(deliveryPerson);
    }

    public async Task<DeliveryPersonStats?> GetStatsAsync(Guid deliveryPersonId, CancellationToken cancellationToken = default)
    {
        var exists = await _db.Repartidores.AsNoTracking().AnyAsync(r => r.UsuarioId == deliveryPersonId, cancellationToken);
        if (!exists)
        {
            return null;
        }

        var now = DateTime.UtcNow;
        var mesActual = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        var asignados = _db.Pedidos.AsNoTracking().Where(p => p.RepartidorId == deliveryPersonId);

        var entregados = asignados.Where(p => p.Estado == OrderStatus.Entregado);

        var tiemposEntrega = await entregados
            .Where(p => p.EnCaminoEn != null && p.EntregadoEn != null)
            .Select(p => p.EntregadoEn!.Value - p.EnCaminoEn!.Value)
            .ToListAsync(cancellationToken);

        var entregasDelMes = await entregados
            .CountAsync(p => p.EntregadoEn >= mesActual, cancellationToken);

        var estaticos = await entregados
            .CountAsync(cancellationToken);

        var activos = await asignados
            .CountAsync(p => p.Estado != OrderStatus.Entregado && p.Estado != OrderStatus.Cancelado, cancellationToken);

        var cancelaciones = await asignados
            .CountAsync(p => p.Estado == OrderStatus.Cancelado, cancellationToken);

        return new DeliveryPersonStats
        {
            DeliveryPersonId = deliveryPersonId,
            EntregasTotales = estaticos,
            EntregasDelMes = entregasDelMes,
            TiempoPromedioEntregaMinutos = tiemposEntrega.Count == 0 ? 0 : tiemposEntrega.Average(t => t.TotalMinutes),
            PedidosAsignadosActivos = activos,
            Cancelaciones = cancelaciones
        };
    }
}