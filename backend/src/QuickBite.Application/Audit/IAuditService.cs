using QuickBite.Domain.Repositories;

namespace QuickBite.Application.Audit;

public interface IAuditService
{
    Task<IReadOnlyList<AuditEntryResponse>> ListAsync(Guid? userId, string? entity, DateTime? from, DateTime? to, CancellationToken ct = default);
}