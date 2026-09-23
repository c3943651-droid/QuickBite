using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Audit;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/audit")]
[Authorize(Roles = Roles.Administrador)]
public class AdminAuditController : ControllerBase
{
    private readonly IAuditService _auditService;

    public AdminAuditController(IAuditService auditService)
    {
        _auditService = auditService;
    }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] Guid? userId, [FromQuery] string? entity, CancellationToken cancellationToken)
        => Ok(await _auditService.ListAsync(userId, entity, null, null, cancellationToken));
}