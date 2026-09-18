using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using QuickBite.Application.Admin;

namespace QuickBite.Api.Controllers;

[ApiController]
[Route("api/v1/admin/reports")]
[Authorize(Roles = "administrador")]
public class AdminReportsController : ControllerBase
{
    private readonly IAdminReportsService _reports;

    public AdminReportsController(IAdminReportsService reports)
    {
        _reports = reports;
    }

    [HttpGet("sales-by-day")]
    public async Task<IActionResult> SalesByDay([FromQuery] DateTime? fechaDesde, [FromQuery] DateTime? fechaHasta, CancellationToken ct)
        => Ok(await _reports.GetSalesByDayAsync(fechaDesde, fechaHasta, ct));

    [HttpGet("top-products")]
    public async Task<IActionResult> TopProducts([FromQuery] int limite = 10, CancellationToken ct = default)
        => Ok(await _reports.GetTopProductsAsync(limite, ct));

    [HttpGet("top-clients")]
    public async Task<IActionResult> TopClients([FromQuery] int limite = 10, CancellationToken ct = default)
        => Ok(await _reports.GetTopClientsAsync(limite, ct));

    [HttpGet("delivery-performance")]
    public async Task<IActionResult> DeliveryPerformance(CancellationToken ct)
        => Ok(await _reports.GetDeliveryPerformanceAsync(ct));
}