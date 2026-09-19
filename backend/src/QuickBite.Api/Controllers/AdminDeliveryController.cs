using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Admin;
using QuickBite.Application.Admin.Dtos;

namespace QuickBite.Api.Controllers;

[ApiController]
[Route("api/v1/admin/delivery-persons")]
[Authorize(Roles = "administrador")]
public class AdminDeliveryController : ControllerBase
{
    private readonly IAdminDeliveryService _delivery;

    public AdminDeliveryController(IAdminDeliveryService delivery)
    {
        _delivery = delivery;
    }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? estado, [FromQuery] int page = 1, [FromQuery] int limit = 10, CancellationToken ct = default)
        => Ok(await _delivery.ListAsync(estado, page, limit, ct));

    [HttpGet("available-users")]
    public async Task<IActionResult> AvailableUsers(CancellationToken ct = default)
        => Ok(await _delivery.GetAvailableUsersAsync(ct));

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateDeliveryPersonRequest req, CancellationToken ct)
        => StatusCode(201, await _delivery.CreateAsync(req, ct));

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateDeliveryPersonRequest req, CancellationToken ct)
        => Ok(await _delivery.UpdateAsync(id, req, ct));

    [HttpPatch("{id:guid}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken ct)
        => Ok(await _delivery.DeactivateAsync(id, ct));

    [HttpGet("{id:guid}/history")]
    public async Task<IActionResult> History(Guid id, [FromQuery] int page = 1, [FromQuery] int limit = 10, CancellationToken ct = default)
        => Ok(await _delivery.GetHistoryAsync(id, page, limit, ct));
}