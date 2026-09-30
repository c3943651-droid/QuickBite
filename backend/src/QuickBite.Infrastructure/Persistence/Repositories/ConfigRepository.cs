using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Persistence.Repositories;

public class ConfigRepository : IConfigRepository
{
    private readonly QuickBiteDbContext _db;

    public ConfigRepository(QuickBiteDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<SystemConfig>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        return await _db.ConfiguracionSistema
            .AsNoTracking()
            .OrderBy(c => c.Clave)
            .ToListAsync(cancellationToken);
    }

    public async Task<SystemConfig?> GetByKeyAsync(string key, CancellationToken cancellationToken = default)
    {
        return await _db.ConfiguracionSistema
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Clave.ToLower() == key.Trim().ToLower(), cancellationToken);
    }

    public async Task UpsertAsync(string key, string value, CancellationToken cancellationToken = default)
    {
        var normalizedKey = key.Trim();
        var config = await _db.ConfiguracionSistema
            .FirstOrDefaultAsync(c => c.Clave.ToLower() == normalizedKey.ToLower(), cancellationToken);

        if (config is null)
        {
            _db.ConfiguracionSistema.Add(new SystemConfig
            {
                Clave = normalizedKey,
                Valor = value,
                Editable = true,
                CreadoEn = DateTime.UtcNow,
                ActualizadoEn = DateTime.UtcNow,
            });
            return;
        }

        config.Valor = value;
        config.ActualizadoEn = DateTime.UtcNow;
    }
}