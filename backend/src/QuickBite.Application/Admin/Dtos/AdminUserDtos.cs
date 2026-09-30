namespace QuickBite.Application.Admin.Dtos;

public sealed record AdminUserListItemResponse(
    Guid Id,
    string Nombre,
    string Email,
    string? Telefono,
    string Rol,
    bool Activo,
    DateTime? UltimoLogin,
    DateTime CreadoEn);

public sealed record AdminUserDetailResponse(
    Guid Id,
    string Nombre,
    string Email,
    string? Telefono,
    string Rol,
    bool Activo,
    DateTime? UltimoLogin,
    DateTime CreadoEn,
    DateTime ActualizadoEn,
    short IntentosFallidos,
    DateTime? BloqueadoHasta,
    string? VehiculoRepartidor,
    int EntregasCompletadas);

public sealed record UpdateUserRoleRequest { public string Rol { get; init; } = string.Empty; }

public sealed record UpdateUserStatusRequest { public bool Activo { get; init; } }