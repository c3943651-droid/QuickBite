using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class AuditRepository : IAuditRepository
{
    private readonly QuickBiteDbContext _db;

    public AuditRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task AddAsync(AuditAction auditAction, CancellationToken cancellationToken = default)
    {
        await _db.AuditoriaAcciones.AddAsync(auditAction, cancellationToken);
    }

    public async Task<IReadOnlyList<AuditAction>> GetFilteredAsync(Guid? userId = null, string? entity = null, DateTime? from = null, DateTime? to = null, CancellationToken cancellationToken = default)
    {
        var query = _db.AuditoriaAcciones
            .AsNoTracking()
            .AsQueryable();

        if (userId.HasValue)
        {
            query = query.Where(a => a.UsuarioId == userId.Value);
        }

        if (!string.IsNullOrWhiteSpace(entity))
        {
            query = query.Where(a => a.Entidad.ToLower() == entity.Trim().ToLower());
        }

        if (from.HasValue)
        {
            query = query.Where(a => a.CreadoEn >= from.Value);
        }

        if (to.HasValue)
        {
            query = query.Where(a => a.CreadoEn <= to.Value);
        }

        return await query
            .OrderByDescending(a => a.CreadoEn)
            .ToListAsync(cancellationToken);
    }
}