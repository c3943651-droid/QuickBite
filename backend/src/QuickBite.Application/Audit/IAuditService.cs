namespace QuickBite.Application.Audit;
public interface IAuditService { Task<IReadOnlyList<Domain.Entities.AuditAction>> ListAsync(Guid? userId, string? entity, DateTime? from, DateTime? to, CancellationToken ct = default); }
