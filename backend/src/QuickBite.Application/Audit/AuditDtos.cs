namespace QuickBite.Application.Audit;

public sealed record AuditUserResponse(Guid Id, string Nombre, string Email);

public sealed record AuditEntryResponse(
    Guid Id,
    Guid? UsuarioId,
    AuditUserResponse? Usuario,
    string Accion,
    string Entidad,
    Guid? EntidadId,
    string? Detalles,
    string? IpOrigen,
    string? UserAgent,
    DateTime CreadoEn);