using QuickBite.Domain.Entities;

namespace QuickBite.Domain.Repositories;

public interface IConfigRepository
{
    Task<IReadOnlyList<SystemConfig>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<SystemConfig?> GetByKeyAsync(string key, CancellationToken cancellationToken = default);
    Task UpdateAsync(string key, string value, CancellationToken cancellationToken = default);
}
