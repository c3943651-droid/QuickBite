using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class ProductRepository : IProductRepository
{
    private const int MaxPageSize = 100;

    private readonly QuickBiteDbContext _db;

    public ProductRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<Product>> GetAllAsync(Guid? categoryId = null, bool? onlyAvailable = null, CancellationToken cancellationToken = default)
    {
        IQueryable<Product> query = _db.Productos
            .AsNoTracking()
            .Include(p => p.Categoria);

        if (categoryId.HasValue)
        {
            query = query.Where(p => p.CategoriaId == categoryId);
        }

        if (onlyAvailable == true)
        {
            query = query.Where(p => p.Disponible && (p.Inventario == null || p.Inventario.Stock > 0));
        }

        return await query.OrderBy(p => p.Nombre).ToListAsync(cancellationToken);
    }

    public async Task<(IReadOnlyList<Product> Items, int TotalCount)> GetPagedAsync(ProductFilterParams filterParams, CancellationToken cancellationToken = default)
    {
        IQueryable<Product> query = _db.Productos
            .AsNoTracking()
            .Include(p => p.Categoria);

        if (filterParams.CategoryId.HasValue)
        {
            query = query.Where(p => p.CategoriaId == filterParams.CategoryId);
        }

        if (!string.IsNullOrWhiteSpace(filterParams.SearchTerm))
        {
            var term = $"%{filterParams.SearchTerm.Trim()}%";
            query = query.Where(p =>
                EF.Functions.ILike(p.Nombre, term) ||
                (p.Descripcion != null && EF.Functions.ILike(p.Descripcion, term)));
        }

        if (filterParams.OnlyAvailable == true)
        {
            query = query.Where(p => p.Disponible && (p.Inventario == null || p.Inventario.Stock > 0));
        }

        if (filterParams.MinPrice.HasValue)
        {
            query = query.Where(p => p.Precio >= filterParams.MinPrice.Value);
        }

        if (filterParams.MaxPrice.HasValue)
        {
            query = query.Where(p => p.Precio <= filterParams.MaxPrice.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        query = filterParams.SortBy switch
        {
            "precio" => filterParams.SortDescending
                ? query.OrderByDescending(p => p.Precio)
                : query.OrderBy(p => p.Precio),
            "actualizado" => filterParams.SortDescending
                ? query.OrderByDescending(p => p.ActualizadoEn)
                : query.OrderBy(p => p.ActualizadoEn),
            "relevancia" => filterParams.SortDescending
                ? query.OrderByDescending(p => p.Nombre)
                : query.OrderBy(p => p.Nombre),
            _ => filterParams.SortDescending
                ? query.OrderByDescending(p => p.Nombre)
                : query.OrderBy(p => p.Nombre)
        };

        var page = Math.Max(1, filterParams.Page);
        var pageSize = Math.Clamp(filterParams.PageSize, 1, MaxPageSize);

        var items = await query
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return (items, totalCount);
    }

    public async Task<Product?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _db.Productos
            .AsNoTracking()
            .Include(p => p.Categoria)
            .Include(p => p.Inventario)
            .Include(p => p.Opciones)
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
    }

    public async Task AddAsync(Product product, CancellationToken cancellationToken = default)
    {
        await _db.Productos.AddAsync(product, cancellationToken);
    }

    public void Update(Product product)
    {
        _db.Productos.Update(product);
    }

    public async Task SoftDeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var product = await _db.Productos.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (product is null)
        {
            return;
        }

        product.Disponible = false;
        product.ActualizadoEn = DateTime.UtcNow;
        _db.Productos.Update(product);
    }
}