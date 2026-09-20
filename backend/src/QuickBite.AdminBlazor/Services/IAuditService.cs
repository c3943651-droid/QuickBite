using QuickBite.AdminBlazor.Models.Audit;

namespace QuickBite.AdminBlazor.Services;

public interface IAuditService
{
    Task<IReadOnlyList<AuditRow>?> GetAllAsync(CancellationToken cancellationToken = default);
}