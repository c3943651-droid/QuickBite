using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class PromotionRepository : IPromotionRepository
{
    private readonly QuickBiteDbContext _db;

    public PromotionRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<Promotion>> GetActiveAsync(CancellationToken cancellationToken = default)
    {
        return await _db.Promociones
            .AsNoTracking()
            .Where(p => p.Activa)
            .OrderBy(p => p.Orden)
            .ToListAsync(cancellationToken);
    }

    public async Task<Promotion?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _db.Promociones
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
    }

    public async Task AddAsync(Promotion promotion, CancellationToken cancellationToken = default)
    {
        await _db.Promociones.AddAsync(promotion, cancellationToken);
    }

    public void Update(Promotion promotion)
    {
        _db.Promociones.Update(promotion);
    }

    public void Delete(Promotion promotion)
    {
        _db.Promociones.Remove(promotion);
    }
}
