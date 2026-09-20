namespace QuickBite.AdminBlazor.Models.Audit;

public sealed record AuditUser
{
    public Guid Id { get; init; }
    public string Nombre { get; init; } = string.Empty;
    public string Email { get; init; } = string.Empty;
}

public sealed record AuditRow
{
    public Guid Id { get; init; }
    public Guid? UsuarioId { get; init; }
    public AuditUser? Usuario { get; init; }
    public string Accion { get; init; } = string.Empty;
    public string Entidad { get; init; } = string.Empty;
    public Guid? EntidadId { get; init; }
    public string? Detalles { get; init; }
    public string? IpOrigen { get; init; }
    public string? UserAgent { get; init; }
    public DateTime CreadoEn { get; init; }

    public string UsuarioNombre => Usuario?.Nombre ?? "—";
}