using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Catalog;
using QuickBite.Application.Catalog.Dtos;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin")]
[Authorize(Roles = Roles.Administrador)]
public class AdminPromotionsController : ControllerBase
{
    private readonly ICatalogService _catalogService;

    public AdminPromotionsController(ICatalogService catalogService)
    {
        _catalogService = catalogService;
    }

    [HttpGet("promotions")]
    public async Task<IActionResult> ListPromotions(CancellationToken cancellationToken)
        => Ok(await _catalogService.GetPromotionsAsync(cancellationToken));

    [HttpPost("promotions")]
    public async Task<IActionResult> CreatePromotion([FromBody] CreatePromotionRequest request, CancellationToken cancellationToken)
        => StatusCode(StatusCodes.Status201Created, await _catalogService.CreatePromotionAsync(request, cancellationToken));

    [HttpPut("promotions/{id:guid}")]
    public async Task<IActionResult> UpdatePromotion(Guid id, [FromBody] UpdatePromotionRequest request, CancellationToken cancellationToken)
        => Ok(await _catalogService.UpdatePromotionAsync(id, request, cancellationToken));

    [HttpDelete("promotions/{id:guid}")]
    public async Task<IActionResult> DeletePromotion(Guid id, CancellationToken cancellationToken)
    {
        await _catalogService.DeletePromotionAsync(id, cancellationToken);
        return NoContent();
    }
}
