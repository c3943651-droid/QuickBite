using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;

namespace QuickBite.Application.Admin;

public sealed class AdminReportsService : IAdminReportsService
{
    private const int MaxLimite = 50;

    private readonly IReportRepository _reports;

    public AdminReportsService(IReportRepository reports)
    {
        _reports = reports;
    }

    public async Task<IReadOnlyList<VentaPorDiaRow>> GetSalesByDayAsync(DateTime? fechaDesde, DateTime? fechaHasta, CancellationToken cancellationToken = default)
    {
        if (fechaDesde != null && fechaHasta != null && fechaDesde >= fechaHasta)
            throw new ValidationException("fecha_hasta", "fecha_hasta debe ser posterior a fecha_desde");

        var desde = fechaDesde?.Date;
        var hasta = fechaHasta?.Date;
        var rows = await _reports.GetSalesByDayAsync(cancellationToken);

        if (desde != null)
            rows = rows.Where(r => r.Dia.Date >= desde.Value).ToList();
        if (hasta != null)
            rows = rows.Where(r => r.Dia.Date <= hasta.Value).ToList();

        return rows.ToList();
    }

    public async Task<IReadOnlyList<ProductoMasVendidoRow>> GetTopProductsAsync(int limite = 10, CancellationToken cancellationToken = default)
    {
        var rows = await _reports.GetTopProductsAsync(cancellationToken);
        return rows.Take(Math.Clamp(limite, 1, MaxLimite)).ToList();
    }

    public async Task<IReadOnlyList<ClienteFrecuenteRow>> GetTopClientsAsync(int limite = 10, CancellationToken cancellationToken = default)
    {
        var rows = await _reports.GetTopClientsAsync(cancellationToken);
        return rows.Take(Math.Clamp(limite, 1, MaxLimite)).ToList();
    }

    public Task<IReadOnlyList<RendimientoRepartidorRow>> GetDeliveryPerformanceAsync(CancellationToken cancellationToken = default)
        => _reports.GetDeliveryPerformanceAsync(cancellationToken);
}