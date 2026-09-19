using QuickBite.Application.Audit;
using QuickBite.Domain.Repositories;
namespace QuickBite.Application.Audit;
public sealed class AuditService : IAuditService
{
    private readonly IUnitOfWork _uow;
    public AuditService(IUnitOfWork uow) { _uow = uow; }
    public Task<IReadOnlyList<Domain.Entities.AuditAction>> ListAsync(Guid? userId, string? entity, DateTime? from, DateTime? to, CancellationToken ct = default) => _uow.Audits.GetFilteredAsync(userId, entity, from, to, entityId: null, cancellationToken: ct);
}
