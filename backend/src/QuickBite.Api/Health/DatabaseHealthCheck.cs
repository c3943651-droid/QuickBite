using Microsoft.Extensions.Diagnostics.HealthChecks;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Api.Health;

public sealed class DatabaseHealthCheck : IHealthCheck
{
    private readonly QuickBiteDbContext _db;

    public DatabaseHealthCheck(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        var canConnect = await _db.Database.CanConnectAsync(cancellationToken);
        return canConnect
            ? HealthCheckResult.Healthy("Base de datos accesible.")
            : HealthCheckResult.Unhealthy("No se puede conectar a la base de datos.");
    }
}