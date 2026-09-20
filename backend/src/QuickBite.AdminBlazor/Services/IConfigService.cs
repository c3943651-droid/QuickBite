using QuickBite.AdminBlazor.Models.Config;

namespace QuickBite.AdminBlazor.Services;

public interface IConfigService
{
    Task<IReadOnlyList<ConfigEntry>?> GetAllAsync(CancellationToken cancellationToken = default);
    Task<bool> UpdateAsync(string key, string value, CancellationToken cancellationToken = default);
}