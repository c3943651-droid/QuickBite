using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Admin;
using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Orders.Dtos;
using QuickBite.Domain.Enums;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/orders")]
[Authorize(Roles = Roles.Administrador)]
public class AdminOrdersController : ControllerBase
{
    private readonly IAdminOrderService _orderService;

    public AdminOrdersController(IAdminOrderService orderService)
    {
        _orderService = orderService;
    }

    [HttpGet]
    public async Task<IActionResult> List(
        [FromQuery] string? search,
        [FromQuery] string? estado,
        [FromQuery] Guid? repartidorId,
        [FromQuery] DateTime? fechaDesde,
        [FromQuery] DateTime? fechaHasta,
        [FromQuery] int page = 1,
        [FromQuery] int limit = 10,
        CancellationToken cancellationToken = default)
    {
        OrderStatus? status = null;
        if (estado != null && Enum.TryParse<OrderStatus>(estado, true, out var parsed))
        {
            status = parsed;
        }

        return Ok(await _orderService.ListAsync(search, status, repartidorId, fechaDesde, fechaHasta, page, limit, cancellationToken));
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id, CancellationToken cancellationToken)
    {
        var order = await _orderService.GetAsync(id, cancellationToken);
        return order == null ? NotFound() : Ok(order);
    }

    [HttpPatch("{id:guid}/status")]
    public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateOrderStatusRequest request, CancellationToken cancellationToken)
    {
        var comentario = string.IsNullOrWhiteSpace(request.Comentario) ? null : request.Comentario;
        return Ok(await _orderService.UpdateStatusAsync(id, request.Estado, comentario, cancellationToken));
    }

    [HttpPatch("{id:guid}/assign")]
    public async Task<IActionResult> Assign(Guid id, [FromBody] AssignDeliveryRequest request, CancellationToken cancellationToken)
    {
        var origin = request.Origin ?? AssignmentOrigin.Auto;
        await _orderService.AssignAsync(id, request.RepartidorId, origin, cancellationToken);
        return NoContent();
    }

    [HttpPatch("{id:guid}/cancel")]
    public async Task<IActionResult> Cancel(Guid id, [FromBody] CancelOrderRequest request, CancellationToken cancellationToken)
    {
        await _orderService.CancelAsync(id, request.Motivo ?? "", cancellationToken);
        return NoContent();
    }
}