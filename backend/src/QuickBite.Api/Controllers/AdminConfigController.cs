using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Notifications;

namespace QuickBite.Api.Controllers;

[ApiController]
[Route("api/v1/admin/config")]
[Authorize(Roles = "administrador")]
public class AdminConfigController : ControllerBase
{
    private readonly IConfigService _config;

    public AdminConfigController(IConfigService config)
    {
        _config = config;
    }

    [HttpGet]
    public async Task<IActionResult> List(CancellationToken ct) => Ok(await _config.ListAsync(ct));

    [HttpPut("{key}")]
    public async Task<IActionResult> Update(string key, [FromBody] Dictionary<string, string> body, CancellationToken ct)
    {
        await _config.UpdateAsync(key, body["value"], ct);
        return NoContent();
    }
}