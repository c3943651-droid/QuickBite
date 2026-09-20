using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Catalog;
using QuickBite.Application.Catalog.Dtos;
namespace QuickBite.Api.Controllers;
[ApiController]
[Route("api/v1/admin")]
[Authorize(Roles = "administrador")]
public class AdminCatalogController : ControllerBase
{
    private readonly ICatalogService _svc;
    public AdminCatalogController(ICatalogService s) { _svc = s; }
    private Guid? Uid => Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var g) ? g : null;
    [HttpGet("categories")] public async Task<IActionResult> ListCats(CancellationToken ct) => Ok(await _svc.GetAdminCategoriesAsync(ct));
    [HttpPost("categories")] public async Task<IActionResult> CreateCat([FromBody] CreateCategoryRequest r, CancellationToken ct) => StatusCode(201, await _svc.CreateCategoryAsync(r, ct));
    [HttpPut("categories/{id:guid}")] public async Task<IActionResult> UpdCat(Guid id, [FromBody] UpdateCategoryRequest r, CancellationToken ct) => Ok(await _svc.UpdateCategoryAsync(id, r, ct));
    [HttpDelete("categories/{id:guid}")] public async Task<IActionResult> DelCat(Guid id, CancellationToken ct) { await _svc.DeleteCategoryAsync(id, ct); return NoContent(); }
    [HttpPost("products")] public async Task<IActionResult> CreateProd([FromBody] CreateProductRequest r, CancellationToken ct) => StatusCode(201, await _svc.CreateProductAsync(r, Uid, ct));
    [HttpPut("products/{id:guid}")] public async Task<IActionResult> UpdProd(Guid id, [FromBody] UpdateProductRequest r, CancellationToken ct) => Ok(await _svc.UpdateProductAsync(id, r, Uid, ct));
    [HttpDelete("products/{id:guid}")] public async Task<IActionResult> DelProd(Guid id, CancellationToken ct) { await _svc.DeleteProductAsync(id, ct); return NoContent(); }
    [HttpPatch("products/{id:guid}/availability")] public async Task<IActionResult> Avail(Guid id, [FromBody] Dictionary<string, bool> body, CancellationToken ct) => Ok(await _svc.SetAvailabilityAsync(id, body["disponible"], ct));
    [HttpPatch("products/{id:guid}/stock")] public async Task<IActionResult> Stock(Guid id, [FromBody] Dictionary<string, object> body, CancellationToken ct) { var stock = Convert.ToInt32(body["stock"]); var motivo = body.ContainsKey("motivo") ? body["motivo"]?.ToString() : null; return Ok(await _svc.AdjustStockAsync(id, stock, motivo, Uid, ct)); }
    [HttpGet("products/{id:guid}/price-history")] public async Task<IActionResult> PriceHistory(Guid id, CancellationToken ct) => Ok(await _svc.GetPriceHistoryAsync(id, ct));
    [HttpPost("products/{id:guid}/options")] public async Task<IActionResult> CreateOpt(Guid id, [FromBody] CreateProductOptionRequest r, CancellationToken ct) => StatusCode(201, await _svc.CreateOptionAsync(id, r, ct));
    [HttpPut("products/{id:guid}/options/{optionId:guid}")] public async Task<IActionResult> UpdOpt(Guid id, Guid optionId, [FromBody] UpdateProductOptionRequest r, CancellationToken ct) => Ok(await _svc.UpdateOptionAsync(id, optionId, r, ct));
    [HttpDelete("products/{id:guid}/options/{optionId:guid}")] public async Task<IActionResult> DelOpt(Guid id, Guid optionId, CancellationToken ct) { await _svc.DeleteOptionAsync(id, optionId, ct); return NoContent(); }
}
