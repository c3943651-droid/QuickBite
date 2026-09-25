using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Admin;
using QuickBite.Application.Admin.Dtos;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/delivery-persons")]
[Authorize(Roles = Roles.Administrador)]
public class AdminDeliveryController : ControllerBase
{
    private readonly IAdminDeliveryService _deliveryService;

    public AdminDeliveryController(IAdminDeliveryService deliveryService)
    {
        _deliveryService = deliveryService;
    }

    [HttpGet]
    public async Task<IActionResult> List([FromQuery] string? estado, [FromQuery] int page = 1, [FromQuery] int limit = 10, CancellationToken cancellationToken = default)
        => Ok(await _deliveryService.ListAsync(estado, page, limit, cancellationToken));

    [HttpGet("available-users")]
    public async Task<IActionResult> AvailableUsers(CancellationToken cancellationToken = default)
        => Ok(await _deliveryService.GetAvailableUsersAsync(cancellationToken));

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateDeliveryPersonRequest request, CancellationToken cancellationToken)
        => StatusCode(StatusCodes.Status201Created, await _deliveryService.CreateAsync(request, cancellationToken));

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateDeliveryPersonRequest request, CancellationToken cancellationToken)
        => Ok(await _deliveryService.UpdateAsync(id, request, cancellationToken));

    [HttpPatch("{id:guid}/deactivate")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken cancellationToken)
        => Ok(await _deliveryService.DeactivateAsync(id, cancellationToken));

    [HttpGet("{id:guid}/history")]
    public async Task<IActionResult> History(Guid id, [FromQuery] int page = 1, [FromQuery] int limit = 10, CancellationToken cancellationToken = default)
        => Ok(await _deliveryService.GetHistoryAsync(id, page, limit, cancellationToken));
}