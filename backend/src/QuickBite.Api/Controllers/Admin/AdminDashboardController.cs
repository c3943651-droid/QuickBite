using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Admin;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/dashboard")]
[Authorize(Roles = Roles.Administrador)]
public class AdminDashboardController : ControllerBase
{
    private readonly IAdminOrderService _service;

    public AdminDashboardController(IAdminOrderService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<IActionResult> Get(CancellationToken cancellationToken)
        => Ok(await _service.DashboardAsync(cancellationToken));
}