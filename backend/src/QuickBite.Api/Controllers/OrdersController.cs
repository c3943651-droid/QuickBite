using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Orders;
using QuickBite.Application.Orders.Dtos;
namespace QuickBite.Api.Controllers;
[ApiController]
[Route("api/v1/orders")]
[Authorize]
public class OrdersController : ControllerBase
{
    private readonly IOrderService _s;
    public OrdersController(IOrderService s) { _s = s; }
    private Guid Uid => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    [HttpPost] public async Task<IActionResult> Create([FromBody] CreateOrderRequest r, CancellationToken ct) => StatusCode(201, await _s.CreateAsync(Uid, r, ct));
    [HttpGet] public async Task<IActionResult> List(CancellationToken ct) => Ok(await _s.ListAsync(Uid, ct));
    [HttpGet("{id:guid}")] public async Task<IActionResult> Get(Guid id, CancellationToken ct) => Ok(await _s.GetAsync(Uid, id, ct));
    [HttpGet("{id:guid}/status")] public async Task<IActionResult> Status(Guid id, CancellationToken ct) => Ok(await _s.GetStatusAsync(Uid, id, ct));
    [HttpPatch("{id:guid}/cancel")] public async Task<IActionResult> Cancel(Guid id, [FromBody] Dictionary<string, string> body, CancellationToken ct) { await _s.CancelAsync(Uid, id, body.GetValueOrDefault("motivo") ?? ""); return NoContent(); }
}
