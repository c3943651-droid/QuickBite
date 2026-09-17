using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Audit;
using QuickBite.Application.Notifications;
namespace QuickBite.Api.Controllers;
[ApiController]
[Route("api/v1/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _n; private readonly IAuditService _a; private readonly IConfigService _c;
    public NotificationsController(INotificationService n, IAuditService a, IConfigService c) { _n = n; _a = a; _c = c; }
    private Guid Uid => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    [HttpGet] public async Task<IActionResult> List([FromQuery] bool? UnreadOnly, CancellationToken ct) => Ok(await _n.ListAsync(Uid, UnreadOnly, ct));
    [HttpPatch("{id:guid}/read")] public async Task<IActionResult> Read(Guid id, CancellationToken ct) { await _n.MarkAsReadAsync(id, ct); return NoContent(); }
    [HttpPatch("read-all")] public async Task<IActionResult> ReadAll(CancellationToken ct) { await _n.MarkAllAsReadAsync(Uid, ct); return NoContent(); }
    [HttpGet("/api/v1/admin/audit")][Authorize(Roles = "administrador")] public async Task<IActionResult> Audit([FromQuery] Guid? userId, [FromQuery] string? entity, CancellationToken ct) => Ok(await _a.ListAsync(userId, entity, null, null, ct));
    [HttpGet("/api/v1/config")] public async Task<IActionResult> Config(CancellationToken ct) => Ok(await _c.ListAsync(ct));
    [HttpPut("/api/v1/admin/config/{key}")][Authorize(Roles = "administrador")] public async Task<IActionResult> UpdConfig(string key, [FromBody] Dictionary<string, string> body, CancellationToken ct) { await _c.UpdateAsync(key, body["value"], ct); return NoContent(); }
}
