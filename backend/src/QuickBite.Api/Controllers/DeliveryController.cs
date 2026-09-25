using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Delivery;

namespace QuickBite.Api.Controllers;

[ApiController]
[Route("api/v1/delivery")]
[Authorize(Roles = Roles.Repartidor)]
public class DeliveryController : ControllerBase
{
    private readonly IDeliveryService _deliveryService;

    public DeliveryController(IDeliveryService deliveryService)
    {
        _deliveryService = deliveryService;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet("available")]
    public async Task<IActionResult> Available(CancellationToken cancellationToken)
        => Ok(await _deliveryService.AvailableAsync(CurrentUserId, cancellationToken));

    [HttpPost("{id:guid}/accept")]
    public async Task<IActionResult> Accept(Guid id, CancellationToken cancellationToken)
    {
        await _deliveryService.AcceptAsync(CurrentUserId, id, cancellationToken);
        return NoContent();
    }

    [HttpGet("active")]
    public async Task<IActionResult> Active(CancellationToken cancellationToken)
        => Ok(await _deliveryService.ActiveAsync(CurrentUserId, cancellationToken));

    [HttpPost("{id:guid}/complete")]
    public async Task<IActionResult> Complete(Guid id, CancellationToken cancellationToken)
    {
        await _deliveryService.CompleteAsync(CurrentUserId, id, cancellationToken);
        return NoContent();
    }

    [HttpGet("history")]
    public async Task<IActionResult> History(CancellationToken cancellationToken)
        => Ok(await _deliveryService.HistoryAsync(CurrentUserId, cancellationToken));

    [HttpGet("stats")]
    public async Task<IActionResult> Stats(CancellationToken cancellationToken)
        => Ok(await _deliveryService.StatsAsync(CurrentUserId, cancellationToken));
}