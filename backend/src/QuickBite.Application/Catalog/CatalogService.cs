using QuickBite.Application.Catalog.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;
namespace QuickBite.Application.Catalog;
public sealed class CatalogService : ICatalogService
{
    private readonly IUnitOfWork _uow;
    public CatalogService(IUnitOfWork uow) { _uow = uow; }
    private static CategoryResponse ToCat(Category c) => new(c.Id, c.Nombre, c.Descripcion, c.Orden, c.Activo);
    private static ProductOptionResponse ToOpt(ProductOption o) => new(o.Id, o.Nombre, o.PrecioAdicional, o.Activo);
    private static ProductListItemResponse ToList(Product p) => new(p.Id, p.Nombre, p.Descripcion, p.Precio, p.ImagenUrl, p.Disponible, p.Categoria == null ? null : new CategoryResponse(p.Categoria.Id, p.Categoria.Nombre, p.Categoria.Descripcion, p.Categoria.Orden, p.Categoria.Activo), p.Inventario?.Stock, p.Inventario?.StockMinimo);
    private static ProductDetailResponse ToDetail(Product p) => new(p.Id, p.Nombre, p.Descripcion, p.Precio, p.ImagenUrl, p.Disponible, p.Categoria == null ? null : new CategoryResponse(p.Categoria.Id, p.Categoria.Nombre, p.Categoria.Descripcion, p.Categoria.Orden, p.Categoria.Activo), p.Opciones.Select(ToOpt).ToList(), p.Inventario?.Stock);

    public async Task<IReadOnlyList<CategoryResponse>> GetCategoriesAsync(CancellationToken ct = default)
    {
        var cats = await _uow.Categories.GetActiveAsync(ct);
        return cats.Select(ToCat).ToList();
    }
    public async Task<CategoryResponse> CreateCategoryAsync(CreateCategoryRequest req, CancellationToken ct = default)
    {
        var cat = new Category { Nombre = req.Nombre.Trim(), Descripcion = req.Descripcion?.Trim(), Orden = req.Orden };
        await _uow.Categories.AddAsync(cat, ct);
        await _uow.SaveChangesAsync(ct);
        return ToCat(cat);
    }
    public async Task<CategoryResponse> UpdateCategoryAsync(Guid id, UpdateCategoryRequest req, CancellationToken ct = default)
    {
        var cat = await _uow.Categories.GetByIdAsync(id, ct) ?? throw new NotFoundException("Categoria", id);
        if (req.Nombre != null) cat.Nombre = req.Nombre.Trim();
        if (req.Descripcion != null) cat.Descripcion = req.Descripcion.Trim();
        if (req.Orden != null) cat.Orden = req.Orden.Value;
        if (req.Activo != null) cat.Activo = req.Activo.Value;
        _uow.Categories.Update(cat);
        await _uow.SaveChangesAsync(ct);
        return ToCat(cat);
    }
    public async Task DeleteCategoryAsync(Guid id, CancellationToken ct = default)
    {
        var cat = await _uow.Categories.GetByIdAsync(id, ct) ?? throw new NotFoundException("Categoria", id);
        cat.Activo = false;
        _uow.Categories.Update(cat);
        await _uow.SaveChangesAsync(ct);
    }
    public async Task<PagedResponse<ProductListItemResponse>> GetProductsAsync(ProductFilterRequest filter, CancellationToken ct = default)
    {
        if (filter.PrecioMin != null && filter.PrecioMax != null && filter.PrecioMin > filter.PrecioMax) throw new ValidationException("precio_min", "precio_min no puede ser mayor que precio_max");
        var sortBy = filter.Orden switch { "precio_asc" => "precio", "precio_desc" => "precio", "nombre_asc" => "nombre", "nombre_desc" => "nombre", _ => null };
        var desc = filter.Orden == "precio_desc" || filter.Orden == "nombre_desc";
        var p = new ProductFilterParams { CategoryId = filter.CategoriaId, SearchTerm = filter.Search, OnlyAvailable = filter.Disponible, MinPrice = filter.PrecioMin, MaxPrice = filter.PrecioMax, SortBy = sortBy, SortDescending = desc, Page = filter.Page, PageSize = filter.Limit };
        var (items, total) = await _uow.Products.GetPagedAsync(p, ct);
        var data = items.Select(ToList).ToList();
        var totalPages = (int)Math.Ceiling((double)total / filter.Limit);
        return new PagedResponse<ProductListItemResponse>(data, total, filter.Page, filter.Limit, totalPages);
    }
    public async Task<ProductDetailResponse> GetProductAsync(Guid id, CancellationToken ct = default)
    {
        var p = await _uow.Products.GetByIdAsync(id, ct) ?? throw new NotFoundException("Producto", id);
        return ToDetail(p);
    }
    public async Task<IReadOnlyList<ProductOptionResponse>> GetProductOptionsAsync(Guid productId, CancellationToken ct = default)
    {
        var p = await _uow.Products.GetByIdAsync(productId, ct) ?? throw new NotFoundException("Producto", productId);
        return p.Opciones.Where(o => o.Activo).Select(ToOpt).ToList();
    }
    public async Task<IReadOnlyList<ProductPriceHistoryResponse>> GetPriceHistoryAsync(Guid productId, CancellationToken ct = default)
    {
        if (!await _uow.Products.ExistsAsync(productId, ct)) throw new NotFoundException("Producto", productId);
        var history = await _uow.Products.GetPriceHistoryAsync(productId, ct);
        return history.Select(h => new ProductPriceHistoryResponse(h.Id, h.PrecioAnterior, h.PrecioNuevo, h.Usuario?.Nombre, h.Motivo, h.CreadoEn)).ToList();
    }
    public async Task<ProductDetailResponse> CreateProductAsync(CreateProductRequest req, Guid? userId = null, CancellationToken ct = default)
    {
        var prod = new Product { Nombre = req.Nombre.Trim(), Descripcion = req.Descripcion?.Trim(), Precio = req.Precio, CategoriaId = req.CategoriaId, ImagenUrl = req.ImagenUrl?.Trim(), Disponible = req.Disponible };
        await _uow.Products.AddAsync(prod, ct);
        // Inventory creation - try generic via Product repo or direct via context
        prod.Inventario = new Inventory { ProductoId = prod.Id, Stock = req.StockInicial, StockMinimo = req.StockMinimo, ActualizadoPor = userId };
        await _uow.SaveChangesAsync(ct);
        var created = await _uow.Products.GetByIdAsync(prod.Id, ct);
        return ToDetail(created!);
    }
    public async Task<ProductDetailResponse> UpdateProductAsync(Guid id, UpdateProductRequest req, Guid? userId = null, CancellationToken ct = default)
    {
        var p = await _uow.Products.GetByIdAsync(id, ct) ?? throw new NotFoundException("Producto", id);
        var oldPrice = p.Precio;
        if (req.Nombre != null) p.Nombre = req.Nombre.Trim();
        if (req.Descripcion != null) p.Descripcion = req.Descripcion?.Trim();
        if (req.CategoriaId != null) p.CategoriaId = req.CategoriaId;
        if (req.ImagenUrl != null) p.ImagenUrl = req.ImagenUrl.Trim();
        if (req.Disponible != null) p.Disponible = req.Disponible.Value;
        if (req.Precio != null && req.Precio != oldPrice)
        {
            p.Precio = req.Precio.Value;
            p.PreciosHistoricos.Add(new ProductPriceHistory { ProductoId = p.Id, PrecioAnterior = oldPrice, PrecioNuevo = p.Precio, UsuarioId = userId, Motivo = "cambio precio" });
        }
        p.ActualizadoEn = DateTime.UtcNow;
        _uow.Products.Update(p);
        await _uow.SaveChangesAsync(ct);
        var upd = await _uow.Products.GetByIdAsync(id, ct);
        return ToDetail(upd!);
    }
    public async Task DeleteProductAsync(Guid id, CancellationToken ct = default) { await _uow.Products.SoftDeleteAsync(id, ct); await _uow.SaveChangesAsync(ct); }
    public async Task<ProductDetailResponse> SetAvailabilityAsync(Guid id, bool disponible, CancellationToken ct = default)
    {
        var p = await _uow.Products.GetByIdAsync(id, ct) ?? throw new NotFoundException("Producto", id);
        p.Disponible = disponible; p.ActualizadoEn = DateTime.UtcNow;
        _uow.Products.Update(p); await _uow.SaveChangesAsync(ct);
        return ToDetail(p);
    }
    public async Task<ProductDetailResponse> AdjustStockAsync(Guid id, int stock, string? motivo, Guid? userId, CancellationToken ct = default)
    {
        if (stock < 0) throw new ValidationException("stock", "stock debe ser >=0");
        var p = await _uow.Products.GetByIdAsync(id, ct) ?? throw new NotFoundException("Producto", id);
        if (p.Inventario == null) p.Inventario = new Inventory { ProductoId = p.Id, Stock = stock, ActualizadoPor = userId };
        else { p.Inventario.Stock = stock; p.Inventario.ActualizadoPor = userId; p.Inventario.UltimaActualizacion = DateTime.UtcNow; }
        _uow.Products.Update(p); await _uow.SaveChangesAsync(ct);
        return ToDetail(p);
    }
    public async Task<ProductOptionResponse> CreateOptionAsync(Guid productId, CreateProductOptionRequest req, CancellationToken ct = default)
    {
        var p = await _uow.Products.GetByIdAsync(productId, ct) ?? throw new NotFoundException("Producto", productId);
        var opt = new ProductOption { ProductoId = productId, Nombre = req.Nombre.Trim(), PrecioAdicional = req.PrecioAdicional, Activo = req.Activo };
        p.Opciones.Add(opt);
        _uow.Products.Update(p); await _uow.SaveChangesAsync(ct);
        return ToOpt(opt);
    }
    public async Task<ProductOptionResponse> UpdateOptionAsync(Guid productId, Guid optionId, UpdateProductOptionRequest req, CancellationToken ct = default)
    {
        var p = await _uow.Products.GetByIdAsync(productId, ct) ?? throw new NotFoundException("Producto", productId);
        var opt = p.Opciones.FirstOrDefault(o => o.Id == optionId) ?? throw new NotFoundException("Opcion", optionId);
        if (req.Nombre != null) opt.Nombre = req.Nombre.Trim();
        if (req.PrecioAdicional != null) opt.PrecioAdicional = req.PrecioAdicional.Value;
        if (req.Activo != null) opt.Activo = req.Activo.Value;
        _uow.Products.Update(p); await _uow.SaveChangesAsync(ct);
        return ToOpt(opt);
    }
    public async Task DeleteOptionAsync(Guid productId, Guid optionId, CancellationToken ct = default)
    {
        var p = await _uow.Products.GetByIdAsync(productId, ct) ?? throw new NotFoundException("Producto", productId);
        var opt = p.Opciones.FirstOrDefault(o => o.Id == optionId) ?? throw new NotFoundException("Opcion", optionId);
        opt.Activo = false;
        _uow.Products.Update(p); await _uow.SaveChangesAsync(ct);
    }
}
