using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class CategoryRepository : ICategoryRepository
{
    private readonly QuickBiteDbContext _db;

    public CategoryRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<Category>> GetActiveAsync(CancellationToken cancellationToken = default)
    {
        return await _db.Categorias
            .AsNoTracking()
            .Where(c => c.Activo)
            .OrderBy(c => c.Orden)
            .ThenBy(c => c.Nombre)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<Category>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _db.Categorias
            .AsNoTracking()
            .OrderBy(c => c.Orden)
            .ThenBy(c => c.Nombre)
            .ToListAsync(cancellationToken);
    }

    public async Task<Category?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _db.Categorias
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
    }

    public async Task AddAsync(Category category, CancellationToken cancellationToken = default)
    {
        await _db.Categorias.AddAsync(category, cancellationToken);
    }

    public void Update(Category category)
    {
        _db.Categorias.Update(category);
    }
}