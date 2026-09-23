using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Api.Configuration;
using QuickBite.Application.Admin;

namespace QuickBite.Api.Controllers.Admin;

[ApiController]
[Route("api/v1/admin/reports")]
[Authorize(Roles = Roles.Administrador)]
public class AdminReportsController : ControllerBase
{
    private readonly IAdminReportsService _reportsService;

    public AdminReportsController(IAdminReportsService reportsService)
    {
        _reportsService = reportsService;
    }

    [HttpGet("sales-by-day")]
    public async Task<IActionResult> SalesByDay([FromQuery] DateTime? fechaDesde, [FromQuery] DateTime? fechaHasta, CancellationToken cancellationToken)
        => Ok(await _reportsService.GetSalesByDayAsync(fechaDesde, fechaHasta, cancellationToken));

    [HttpGet("top-products")]
    public async Task<IActionResult> TopProducts([FromQuery] int limite = 10, CancellationToken cancellationToken = default)
        => Ok(await _reportsService.GetTopProductsAsync(limite, cancellationToken));

    [HttpGet("top-clients")]
    public async Task<IActionResult> TopClients([FromQuery] int limite = 10, CancellationToken cancellationToken = default)
        => Ok(await _reportsService.GetTopClientsAsync(limite, cancellationToken));

    [HttpGet("delivery-performance")]
    public async Task<IActionResult> DeliveryPerformance(CancellationToken cancellationToken)
        => Ok(await _reportsService.GetDeliveryPerformanceAsync(cancellationToken));
}