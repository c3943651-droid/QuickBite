using QuickBite.Domain.Entities;
using QuickBite.Domain.Repositories;

namespace QuickBite.Application.Audit;

public sealed class AuditService : IAuditService
{
    private readonly IUnitOfWork _uow;

    public AuditService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<IReadOnlyList<AuditEntryResponse>> ListAsync(Guid? userId, string? entity, DateTime? from, DateTime? to, CancellationToken ct = default)
    {
        var items = await _uow.Audits.GetFilteredAsync(userId, entity, from, to, entityId: null, cancellationToken: ct);
        return items.Select(ToResponse).ToList();
    }

    private static AuditEntryResponse ToResponse(AuditAction action) => new(
        action.Id,
        action.UsuarioId,
        action.Usuario is null ? null : new AuditUserResponse(action.Usuario.Id, action.Usuario.Nombre, action.Usuario.Email),
        action.Accion,
        action.Entidad,
        action.EntidadId,
        action.Detalles,
        action.IpOrigen,
        action.UserAgent,
        action.CreadoEn);
}