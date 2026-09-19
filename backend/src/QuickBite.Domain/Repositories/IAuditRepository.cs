using QuickBite.Domain.Entities;

namespace QuickBite.Domain.Repositories;

public interface IAuditRepository
{
    Task AddAsync(AuditAction auditAction, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<AuditAction>> GetFilteredAsync(Guid? userId = null, string? entity = null, DateTime? from = null, DateTime? to = null, Guid? entityId = null, CancellationToken cancellationToken = default);
}
