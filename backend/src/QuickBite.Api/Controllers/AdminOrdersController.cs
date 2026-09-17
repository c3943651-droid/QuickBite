using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Admin;
using QuickBite.Domain.Enums;
namespace QuickBite.Api.Controllers;
[ApiController]
[Route("api/v1/admin/orders")]
[Authorize(Roles = "administrador")]
public class AdminOrdersController : ControllerBase
{
    private readonly IAdminOrderService _s;
    public AdminOrdersController(IAdminOrderService s) { _s = s; }
    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? estado, [FromQuery] Guid? repartidorId, CancellationToken ct)
    {
        OrderStatus? st = null; if (estado != null && Enum.TryParse<OrderStatus>(estado, true, out var p)) st = p;
        return Ok(await _s.ListAsync(st, repartidorId, ct));
    }
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken ct)
    {
        var list = await _s.ListAsync(null, null, ct);
        var o = list.FirstOrDefault(x => x.Id == id); if (o == null) return NotFound(); return Ok(o);
    }
    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> Status(Guid id, [FromBody] Dictionary<string, string> body, CancellationToken ct)
    {
        var st = Enum.Parse<OrderStatus>(body["estado"], true);
        return Ok(await _s.UpdateStatusAsync(id, st, ct));
    }
    [HttpPatch("{id:guid}/assign")]
    public async Task<IActionResult> Assign(Guid id, [FromBody] Dictionary<string, string> body, CancellationToken ct)
    {
        var rep = Guid.Parse(body["repartidorId"]); var origin = body.GetValueOrDefault("origin", "auto") == "assisted" ? AssignmentOrigin.Assisted : AssignmentOrigin.Auto;
        await _s.AssignAsync(id, rep, origin, ct); return NoContent();
    }
    [HttpPatch("{id:guid}/cancel")] public async Task<IActionResult> Cancel(Guid id, [FromBody] Dictionary<string, string> body, CancellationToken ct) { await _s.CancelAsync(id, body.GetValueOrDefault("motivo") ?? "", ct); return NoContent(); }
}
[ApiController]
[Route("api/v1/admin/dashboard")]
[Authorize(Roles = "administrador")]
public class AdminDashboardController : ControllerBase
{
    private readonly IAdminOrderService _s;
    public AdminDashboardController(IAdminOrderService s) { _s = s; }
    [HttpGet] public async Task<IActionResult> Get(CancellationToken ct) => Ok(await _s.DashboardAsync(ct));
}
