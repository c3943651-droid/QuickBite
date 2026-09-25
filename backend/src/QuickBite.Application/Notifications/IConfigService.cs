namespace QuickBite.Application.Notifications;
public interface IConfigService { Task<IReadOnlyList<Domain.Entities.SystemConfig>> ListAsync(CancellationToken ct = default); Task UpdateAsync(string key, string value, CancellationToken ct = default); }
