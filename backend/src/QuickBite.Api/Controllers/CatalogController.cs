using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Catalog;
using QuickBite.Application.Catalog.Dtos;

namespace QuickBite.Api.Controllers;

[ApiController]
[Route("api/v1")]
public class CatalogController : ControllerBase
{
    private readonly ICatalogService _catalogService;

    public CatalogController(ICatalogService catalogService)
    {
        _catalogService = catalogService;
    }

    [HttpGet("categories")]
    [AllowAnonymous]
    public async Task<IActionResult> GetCategories(CancellationToken cancellationToken)
        => Ok(await _catalogService.GetCategoriesAsync(cancellationToken));

    [HttpGet("products")]
    [AllowAnonymous]
    public async Task<IActionResult> GetProducts(
        [FromQuery] Guid? categoriaId,
        [FromQuery] string? search,
        [FromQuery] bool? disponible,
        [FromQuery] decimal? precioMin,
        [FromQuery] decimal? precioMax,
        [FromQuery] string? orden,
        [FromQuery] int page = 1,
        [FromQuery] int limit = 10,
        CancellationToken cancellationToken = default)
        => Ok(await _catalogService.GetProductsAsync(new ProductFilterRequest
        {
            CategoriaId = categoriaId,
            Search = search,
            Disponible = disponible,
            PrecioMin = precioMin,
            PrecioMax = precioMax,
            Orden = orden,
            Page = page,
            Limit = limit
        }, cancellationToken));

    [HttpGet("products/{id:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetProduct(Guid id, CancellationToken cancellationToken)
        => Ok(await _catalogService.GetProductAsync(id, cancellationToken));

    [HttpGet("products/{id:guid}/options")]
    [AllowAnonymous]
    public async Task<IActionResult> GetProductOptions(Guid id, CancellationToken cancellationToken)
        => Ok(await _catalogService.GetProductOptionsAsync(id, cancellationToken));
}