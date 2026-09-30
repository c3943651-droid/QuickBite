using QuickBite.Application.Notifications;
using QuickBite.Domain.Repositories;
namespace QuickBite.Application.Notifications;
public sealed class ConfigService : IConfigService
{
    private readonly IUnitOfWork _uow;
    public ConfigService(IUnitOfWork uow) { _uow = uow; }
    public Task<IReadOnlyList<Domain.Entities.SystemConfig>> ListAsync(CancellationToken ct = default) => _uow.Config.GetAllAsync(ct);
    public async Task UpdateAsync(string key, string value, CancellationToken ct = default) { await _uow.Config.UpsertAsync(key, value, ct); await _uow.SaveChangesAsync(ct); }
}
