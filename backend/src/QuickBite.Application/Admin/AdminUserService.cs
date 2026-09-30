using QuickBite.Application.Admin.Dtos;
using QuickBite.Application.Catalog.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;

namespace QuickBite.Application.Admin;

public sealed class AdminUserService : IAdminUserService
{
    private readonly IUnitOfWork _uow;

    public AdminUserService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    private static string RolToString(UserRole rol) => rol.ToString().ToLowerInvariant();

    private static AdminUserListItemResponse ToItem(User user) => new(
        user.Id,
        user.Nombre,
        user.Email,
        user.Telefono,
        RolToString(user.Rol),
        user.Activo,
        user.UltimoLogin,
        user.CreadoEn);

    private static AdminUserDetailResponse ToDetail(User user) => new(
        user.Id,
        user.Nombre,
        user.Email,
        user.Telefono,
        RolToString(user.Rol),
        user.Activo,
        user.UltimoLogin,
        user.CreadoEn,
        user.ActualizadoEn,
        user.IntentosFallidos,
        user.BloqueadoHasta,
        user.Repartidor?.Vehiculo,
        user.Repartidor?.EntregasCompletadas ?? 0);

    public async Task<PagedResponse<AdminUserListItemResponse>> ListAsync(string? search, string? rol, bool? activo, int page, int limit, CancellationToken ct = default)
    {
        UserRole? roleFilter = null;
        if (!string.IsNullOrWhiteSpace(rol))
        {
            if (!Enum.TryParse<UserRole>(rol, ignoreCase: true, out var parsed))
                throw new ValidationException("rol", "rol inválido. Valores: cliente, administrador, repartidor");
            roleFilter = parsed;
        }

        var (items, total) = await _uow.Users.GetPagedAsync(Trimmed(search), roleFilter, activo, page, limit, ct);
        var data = items.Select(ToItem).ToList();
        var totalPages = (int)Math.Ceiling((double)total / Math.Max(1, limit));
        return new PagedResponse<AdminUserListItemResponse>(data, total, Math.Max(1, page), limit, totalPages);
    }

    public async Task<AdminUserDetailResponse> GetByIdAsync(Guid id, CancellationToken ct = default)
        => ToDetail(await GetUserAsync(id, ct));

    public async Task<AdminUserDetailResponse> UpdateRoleAsync(Guid id, UpdateUserRoleRequest request, Guid currentUserId, CancellationToken ct = default)
    {
        var user = await GetUserAsync(id, ct);

        if (user.Id == currentUserId)
            throw new ForbiddenException("No puedes cambiar el rol de tu propia cuenta.");

        if (!Enum.TryParse<UserRole>(request.Rol, ignoreCase: true, out var role) ||
            !IsValidRole(role))
            throw new ValidationException("rol", "rol inválido. Valores: cliente, administrador, repartidor");

        if (role != UserRole.Repartidor && user.Repartidor is not null)
            throw new BusinessRuleException("El usuario está registrado como repartidor. Cambia su rol desde la gestión de repartidores.");

        user.Rol = role;
        user.ActualizadoEn = DateTime.UtcNow;
        _uow.Users.Update(user);
        await _uow.SaveChangesAsync(ct);
        return ToDetail(user);
    }

    public async Task<AdminUserDetailResponse> UpdateStatusAsync(Guid id, UpdateUserStatusRequest request, Guid currentUserId, CancellationToken ct = default)
    {
        var user = await GetUserAsync(id, ct);

        if (user.Id == currentUserId)
            throw new ForbiddenException("No puedes desactivar tu propia cuenta.");

        user.Activo = request.Activo;
        user.ActualizadoEn = DateTime.UtcNow;
        _uow.Users.Update(user);

        if (!request.Activo)
        {
            var sessions = await _uow.Users.GetActiveSessionsAsync(id, ct);
            foreach (var session in sessions)
            {
                await _uow.Users.RevokeSessionAsync(session.SessionId, id, ct);
            }
        }

        await _uow.SaveChangesAsync(ct);
        return ToDetail(user);
    }

    private async Task<User> GetUserAsync(Guid id, CancellationToken ct)
        => await _uow.Users.GetByIdAsync(id, ct) ?? throw new NotFoundException("usuario", id);

    private static bool IsValidRole(UserRole role)
        => role is UserRole.Cliente or UserRole.Administrador or UserRole.Repartidor;

    private static string? Trimmed(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}