using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Admin;
using QuickBite.Application.Admin.Dtos;
using System.Security.Claims;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/users")]
[Authorize(Roles = Roles.Administrador)]
public class AdminUserController : ControllerBase
{
    private readonly IAdminUserService _users;

    public AdminUserController(IAdminUserService users)
    {
        _users = users;
    }

    private Guid CurrentUserId => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? search, [FromQuery] string? rol, [FromQuery] bool? activo, [FromQuery] int page = 1, [FromQuery] int limit = 10, CancellationToken cancellationToken = default)
        => Ok(await _users.ListAsync(search, rol, activo, page, limit, cancellationToken));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Detail(Guid id, CancellationToken cancellationToken)
        => Ok(await _users.GetByIdAsync(id, cancellationToken));

    [HttpPut("{id:guid}/role")]
    public async Task<IActionResult> UpdateRole(Guid id, [FromBody] UpdateUserRoleRequest request, CancellationToken cancellationToken)
        => Ok(await _users.UpdateRoleAsync(id, request, CurrentUserId, cancellationToken));

    [HttpPut("{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateUserStatusRequest request, CancellationToken cancellationToken)
        => Ok(await _users.UpdateStatusAsync(id, request, CurrentUserId, cancellationToken));
}