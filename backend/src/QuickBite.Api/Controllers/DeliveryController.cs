using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Delivery;
namespace QuickBite.Api.Controllers;
[ApiController]
[Route("api/v1/delivery")]
[Authorize(Roles = "repartidor")]
public class DeliveryController : ControllerBase
{
    private readonly IDeliveryService _s;
    public DeliveryController(IDeliveryService s) { _s = s; }
    private Guid Uid => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    [HttpGet("available")] public async Task<IActionResult> Avail(CancellationToken ct) => Ok(await _s.AvailableAsync(Uid, ct));
    [HttpPost("{id:guid}/accept")] public async Task<IActionResult> Accept(Guid id, CancellationToken ct) { await _s.AcceptAsync(Uid, id, ct); return NoContent(); }
    [HttpGet("active")] public async Task<IActionResult> Active(CancellationToken ct) => Ok(await _s.ActiveAsync(Uid, ct));
    [HttpPost("{id:guid}/complete")] public async Task<IActionResult> Complete(Guid id, CancellationToken ct) { await _s.CompleteAsync(Uid, id, ct); return NoContent(); }
    [HttpGet("history")] public async Task<IActionResult> Hist(CancellationToken ct) => Ok(await _s.HistoryAsync(Uid, ct));
    [HttpGet("stats")] public async Task<IActionResult> Stats(CancellationToken ct) => Ok(await _s.StatsAsync(Uid, ct));
}
