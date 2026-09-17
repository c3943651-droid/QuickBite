using QuickBite.Application.Authentication;
using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Common;
using QuickBite.Application.Users.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;

namespace QuickBite.Application.Users;

public sealed class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ISecureTokenGenerator _tokenGenerator;

    public UserService(IUnitOfWork unitOfWork, IPasswordHasher passwordHasher, ISecureTokenGenerator tokenGenerator)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _tokenGenerator = tokenGenerator;
    }

    public async Task<UserProfileResponse> GetProfileAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var user = await GetUserAsync(userId, cancellationToken);
        return ToProfile(user);
    }

    public async Task<UserProfileResponse> UpdateProfileAsync(Guid userId, UpdateProfileRequest request, CancellationToken cancellationToken = default)
    {
        var user = await GetUserAsync(userId, cancellationToken);

        if (request.Nombre is not null)
        {
            user.Nombre = request.Nombre.Trim();
        }

        if (request.Telefono is not null)
        {
            user.Telefono = string.IsNullOrWhiteSpace(request.Telefono) ? null : request.Telefono.Trim();
        }

        user.ActualizadoEn = DateTime.UtcNow;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return ToProfile(user);
    }

    public async Task<MessageResponse> ChangePasswordAsync(Guid userId, ChangePasswordRequest request, CancellationToken cancellationToken = default)
    {
        var user = await GetUserAsync(userId, cancellationToken);

        if (!_passwordHasher.Verify(request.CurrentPassword, user.PasswordHash))
        {
            throw new ValidationException("currentPassword", "La contraseña actual es incorrecta.");
        }

        user.PasswordHash = _passwordHasher.Hash(request.NewPassword);
        user.IntentosFallidos = 0;
        user.BloqueadoHasta = null;
        user.ActualizadoEn = DateTime.UtcNow;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new MessageResponse("Contraseña actualizada correctamente.");
    }

    public async Task<IReadOnlyList<AddressResponse>> GetAddressesAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var addresses = await _unitOfWork.Addresses.GetByUserIdAsync(userId, cancellationToken);
        return addresses.Select(ToAddress).ToList();
    }

    public async Task<AddressResponse> CreateAddressAsync(Guid userId, CreateAddressRequest request, CancellationToken cancellationToken = default)
    {
        var address = new Address
        {
            UsuarioId = userId,
            Alias = Normalize(request.Alias),
            Calle = request.Calle.Trim(),
            Numero = Normalize(request.Numero),
            Referencia = Normalize(request.Referencia),
            Ciudad = request.Ciudad.Trim(),
            Latitud = request.Latitud,
            Longitud = request.Longitud,
            EsPredeterminada = request.EsPredeterminada
        };

        await _unitOfWork.Addresses.AddAsync(address, cancellationToken);

        if (address.EsPredeterminada)
        {
            await _unitOfWork.Addresses.SetDefaultAsync(address.Id, userId, cancellationToken);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return ToAddress(address);
    }

    public async Task<AddressResponse> UpdateAddressAsync(Guid userId, Guid addressId, UpdateAddressRequest request, CancellationToken cancellationToken = default)
    {
        var address = await GetOwnedAddressAsync(userId, addressId, cancellationToken);

        if (request.Alias is not null)
        {
            address.Alias = Normalize(request.Alias);
        }

        if (request.Calle is not null)
        {
            address.Calle = request.Calle.Trim();
        }

        if (request.Numero is not null)
        {
            address.Numero = Normalize(request.Numero);
        }

        if (request.Referencia is not null)
        {
            address.Referencia = Normalize(request.Referencia);
        }

        if (request.Ciudad is not null)
        {
            address.Ciudad = request.Ciudad.Trim();
        }

        if (request.Latitud is not null)
        {
            address.Latitud = request.Latitud;
        }

        if (request.Longitud is not null)
        {
            address.Longitud = request.Longitud;
        }

        _unitOfWork.Addresses.Update(address);

        if (request.EsPredeterminada == true)
        {
            await _unitOfWork.Addresses.SetDefaultAsync(addressId, userId, cancellationToken);
        }
        else if (request.EsPredeterminada == false)
        {
            address.EsPredeterminada = false;
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return ToAddress(address);
    }

    public async Task DeleteAddressAsync(Guid userId, Guid addressId, CancellationToken cancellationToken = default)
    {
        var address = await GetOwnedAddressAsync(userId, addressId, cancellationToken);
        _unitOfWork.Addresses.Delete(address);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }

    public async Task<AddressResponse> SetDefaultAddressAsync(Guid userId, Guid addressId, CancellationToken cancellationToken = default)
    {
        var address = await GetOwnedAddressAsync(userId, addressId, cancellationToken);
        await _unitOfWork.Addresses.SetDefaultAsync(addressId, userId, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        address.EsPredeterminada = true;
        return ToAddress(address);
    }

    public async Task<IReadOnlyList<SessionResponse>> GetSessionsAsync(Guid userId, string? currentRefreshToken, CancellationToken cancellationToken = default)
    {
        var sessions = await _unitOfWork.Users.GetActiveSessionsAsync(userId, cancellationToken);

        Guid? currentSessionId = null;
        if (!string.IsNullOrWhiteSpace(currentRefreshToken))
        {
            var hash = _tokenGenerator.Hash(currentRefreshToken);
            var current = await _unitOfWork.Users.GetRefreshTokenByHashAsync(hash, cancellationToken);
            if (current is not null && current.UsuarioId == userId)
            {
                currentSessionId = current.Id;
            }
        }

        return sessions
            .Select(session => new SessionResponse
            {
                Id = session.SessionId,
                IpOrigen = session.IpOrigen,
                UserAgent = session.UserAgent,
                CreadoEn = session.CreadoEn,
                ExpiraEn = session.ExpiraEn,
                EsActual = currentSessionId is not null && session.SessionId == currentSessionId
            })
            .ToList();
    }

    public async Task RevokeSessionAsync(Guid userId, Guid sessionId, CancellationToken cancellationToken = default)
    {
        var revoked = await _unitOfWork.Users.RevokeSessionAsync(sessionId, userId, cancellationToken);
        if (!revoked)
        {
            throw new NotFoundException("Sesión no encontrada o no pertenece al usuario.");
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }

    private async Task<User> GetUserAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            throw new NotFoundException("Usuario no encontrado.");
        }

        return user;
    }

    private async Task<Address> GetOwnedAddressAsync(Guid userId, Guid addressId, CancellationToken cancellationToken)
    {
        var address = await _unitOfWork.Addresses.GetByIdAsync(addressId, cancellationToken);
        if (address is null || address.UsuarioId != userId)
        {
            throw new NotFoundException("Dirección no encontrada.");
        }

        return address;
    }

    private static UserProfileResponse ToProfile(User user)
    {
        return new UserProfileResponse
        {
            Id = user.Id,
            Nombre = user.Nombre,
            Email = user.Email,
            Telefono = user.Telefono,
            Rol = UserRoleNames.From(user.Rol),
            CreadoEn = user.CreadoEn,
            UltimoLogin = user.UltimoLogin
        };
    }

    private static AddressResponse ToAddress(Address address)
    {
        return new AddressResponse
        {
            Id = address.Id,
            Alias = address.Alias,
            Calle = address.Calle,
            Numero = address.Numero,
            Referencia = address.Referencia,
            Ciudad = address.Ciudad,
            Latitud = address.Latitud,
            Longitud = address.Longitud,
            EsPredeterminada = address.EsPredeterminada,
            CreadoEn = address.CreadoEn
        };
    }

    private static string? Normalize(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
