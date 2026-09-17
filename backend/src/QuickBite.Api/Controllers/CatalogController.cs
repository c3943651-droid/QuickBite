using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Catalog;
using QuickBite.Application.Catalog.Dtos;
namespace QuickBite.Api.Controllers;
[ApiController]
public class CatalogController : ControllerBase
{
    private readonly ICatalogService _svc;
    public CatalogController(ICatalogService s) { _svc = s; }
    [HttpGet("api/v1/categories")][AllowAnonymous] public async Task<IActionResult> GetCats(CancellationToken ct) => Ok(await _svc.GetCategoriesAsync(ct));
    [HttpGet("api/v1/products")]
    [AllowAnonymous]
    public async Task<IActionResult> GetProducts([FromQuery] Guid? categoria_id, [FromQuery] string? search, [FromQuery] bool? disponible, [FromQuery] decimal? precio_min, [FromQuery] decimal? precio_max, [FromQuery] string? orden, [FromQuery] int page = 1, [FromQuery] int limit = 10, CancellationToken ct = default)
        => Ok(await _svc.GetProductsAsync(new ProductFilterRequest { CategoriaId = categoria_id, Search = search, Disponible = disponible, PrecioMin = precio_min, PrecioMax = precio_max, Orden = orden, Page = page, Limit = limit }, ct));
    [HttpGet("api/v1/products/{id:guid}")][AllowAnonymous] public async Task<IActionResult> GetOne(Guid id, CancellationToken ct) => Ok(await _svc.GetProductAsync(id, ct));
    [HttpGet("api/v1/products/{id:guid}/options")][AllowAnonymous] public async Task<IActionResult> GetOpts(Guid id, CancellationToken ct) => Ok(await _svc.GetProductOptionsAsync(id, ct));
}
