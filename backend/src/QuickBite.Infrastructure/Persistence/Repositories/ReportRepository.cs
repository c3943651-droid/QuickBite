using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Repositories;
using QuickBite.Domain.Repositories.Models;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public sealed class ReportRepository : IReportRepository
{
    private readonly QuickBiteDbContext _db;

    public ReportRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<VentaPorDiaRow>> GetSalesByDayAsync(CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
              dia AS Dia,
              total_pedidos::int AS TotalPedidos,
              entregados::int AS Entregados,
              cancelados::int AS Cancelados,
              activos::int AS Activos,
              ingresos AS Ingresos,
              ticket_promedio AS TicketPromedio
            FROM vista_pedidos_por_dia
            """;

        return await _db.Database.SqlQueryRaw<VentaPorDiaRow>(sql).ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<ProductoMasVendidoRow>> GetTopProductsAsync(CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
              producto_id AS ProductoId,
              nombre_producto AS NombreProducto,
              unidades_vendidas::int AS UnidadesVendidas,
              ingresos_generados AS IngresosGenerados,
              numero_pedidos::int AS NumeroPedidos
            FROM vista_productos_mas_vendidos
            """;

        return await _db.Database.SqlQueryRaw<ProductoMasVendidoRow>(sql).ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<ClienteFrecuenteRow>> GetTopClientsAsync(CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
              cliente_id AS ClienteId,
              nombre AS Nombre,
              email AS Email,
              total_pedidos::int AS TotalPedidos,
              gasto_total AS GastoTotal,
              gasto_promedio AS GastoPromedio,
              ultimo_pedido AS UltimoPedido
            FROM vista_clientes_frecuentes
            """;

        return await _db.Database.SqlQueryRaw<ClienteFrecuenteRow>(sql).ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<RendimientoRepartidorRow>> GetDeliveryPerformanceAsync(CancellationToken cancellationToken = default)
    {
        const string sql = """
            SELECT
              repartidor_id AS RepartidorId,
              nombre AS Nombre,
              entregas_completadas::int AS EntregasCompletadas,
              pedidos_asignados::int AS PedidosAsignados,
              minutos_promedio_entrega AS MinutosPromedioEntrega,
              cancelaciones::int AS Cancelaciones
            FROM vista_rendimiento_repartidores
            """;

        return await _db.Database.SqlQueryRaw<RendimientoRepartidorRow>(sql).ToListAsync(cancellationToken);
    }
}