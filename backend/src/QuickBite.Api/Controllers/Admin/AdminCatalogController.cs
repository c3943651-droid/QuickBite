using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Catalog;
using QuickBite.Application.Catalog.Dtos;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin")]
[Authorize(Roles = Roles.Administrador)]
public class AdminCatalogController : ControllerBase
{
    private readonly ICatalogService _catalogService;

    public AdminCatalogController(ICatalogService catalogService)
    {
        _catalogService = catalogService;
    }

    private Guid? CurrentUserId => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId) ? userId : null;

    [HttpGet("categories")]
    public async Task<IActionResult> ListCategories(CancellationToken cancellationToken)
        => Ok(await _catalogService.GetAdminCategoriesAsync(cancellationToken));

    [HttpPost("categories")]
    public async Task<IActionResult> CreateCategory([FromBody] CreateCategoryRequest request, CancellationToken cancellationToken)
        => StatusCode(StatusCodes.Status201Created, await _catalogService.CreateCategoryAsync(request, cancellationToken));

    [HttpPut("categories/{id:guid}")]
    public async Task<IActionResult> UpdateCategory(Guid id, [FromBody] UpdateCategoryRequest request, CancellationToken cancellationToken)
        => Ok(await _catalogService.UpdateCategoryAsync(id, request, cancellationToken));

    [HttpDelete("categories/{id:guid}")]
    public async Task<IActionResult> DeleteCategory(Guid id, CancellationToken cancellationToken)
    {
        await _catalogService.DeleteCategoryAsync(id, cancellationToken);
        return NoContent();
    }

    [HttpPost("products")]
    public async Task<IActionResult> CreateProduct([FromBody] CreateProductRequest request, CancellationToken cancellationToken)
        => StatusCode(StatusCodes.Status201Created, await _catalogService.CreateProductAsync(request, CurrentUserId, cancellationToken));

    [HttpPut("products/{id:guid}")]
    public async Task<IActionResult> UpdateProduct(Guid id, [FromBody] UpdateProductRequest request, CancellationToken cancellationToken)
        => Ok(await _catalogService.UpdateProductAsync(id, request, CurrentUserId, cancellationToken));

    [HttpDelete("products/{id:guid}")]
    public async Task<IActionResult> DeleteProduct(Guid id, CancellationToken cancellationToken)
    {
        await _catalogService.DeleteProductAsync(id, cancellationToken);
        return NoContent();
    }

    [HttpPatch("products/{id:guid}/availability")]
    public async Task<IActionResult> SetAvailability(Guid id, [FromBody] SetAvailabilityRequest request, CancellationToken cancellationToken)
        => Ok(await _catalogService.SetAvailabilityAsync(id, request.Disponible, cancellationToken));

    [HttpPatch("products/{id:guid}/stock")]
    public async Task<IActionResult> AdjustStock(Guid id, [FromBody] AdjustStockRequest request, CancellationToken cancellationToken)
        => Ok(await _catalogService.AdjustStockAsync(id, request.Stock, request.Motivo, CurrentUserId, cancellationToken));

    [HttpGet("products/{id:guid}/price-history")]
    public async Task<IActionResult> PriceHistory(Guid id, CancellationToken cancellationToken)
        => Ok(await _catalogService.GetPriceHistoryAsync(id, cancellationToken));

    [HttpPost("products/{id:guid}/options")]
    public async Task<IActionResult> CreateOption(Guid id, [FromBody] CreateProductOptionRequest request, CancellationToken cancellationToken)
        => StatusCode(StatusCodes.Status201Created, await _catalogService.CreateOptionAsync(id, request, cancellationToken));

    [HttpPut("products/{id:guid}/options/{optionId:guid}")]
    public async Task<IActionResult> UpdateOption(Guid id, Guid optionId, [FromBody] UpdateProductOptionRequest request, CancellationToken cancellationToken)
        => Ok(await _catalogService.UpdateOptionAsync(id, optionId, request, cancellationToken));

    [HttpDelete("products/{id:guid}/options/{optionId:guid}")]
    public async Task<IActionResult> DeleteOption(Guid id, Guid optionId, CancellationToken cancellationToken)
    {
        await _catalogService.DeleteOptionAsync(id, optionId, cancellationToken);
        return NoContent();
    }

    [HttpPost("products/upload-image")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> UploadProductImage(IFormFile file, CancellationToken cancellationToken)
    {
        if (file is null || file.Length == 0)
        {
            return BadRequest(new { error = "No se ha proporcionado ningún archivo." });
        }

        await using var stream = file.OpenReadStream();
        var imageUrl = await _catalogService.UploadImageAsync(stream, file.FileName, cancellationToken);
        return Ok(new { imageUrl });
    }
}