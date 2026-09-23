using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Notifications;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/config")]
[Authorize(Roles = Roles.Administrador)]
public class AdminConfigController : ControllerBase
{
    private readonly IConfigService _configService;

    public AdminConfigController(IConfigService configService)
    {
        _configService = configService;
    }

    [HttpGet]
    public async Task<IActionResult> List(CancellationToken cancellationToken)
        => Ok(await _configService.ListAsync(cancellationToken));

    [HttpPut("{key}")]
    public async Task<IActionResult> Update(string key, [FromBody] UpdateConfigRequest request, CancellationToken cancellationToken)
    {
        await _configService.UpdateAsync(key, request.Value, cancellationToken);
        return NoContent();
    }
}