using QuickBite.Application.Authentication.Dtos;
using QuickBite.Application.Authentication.Models;
using QuickBite.Application.Common;
using QuickBite.Application.Configuration;
using QuickBite.Application.Email;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Exceptions;
using QuickBite.Domain.Repositories;

namespace QuickBite.Application.Authentication;

public sealed class AuthService : IAuthService
{
    private const short MaxFailedAttempts = 5;
    private const int LockoutMinutes = 15;
    private const int ResetTokenHours = 1;
    private const string GenericForgotMessage =
        "Si el correo está registrado, recibirás un enlace para restablecer tu contraseña.";

    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ISecureTokenGenerator _tokenGenerator;
    private readonly IJwtTokenGenerator _jwtTokenGenerator;
    private readonly IEmailService _emailService;
    private readonly JwtSettings _jwtSettings;

    public AuthService(
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        ISecureTokenGenerator tokenGenerator,
        IJwtTokenGenerator jwtTokenGenerator,
        IEmailService emailService,
        JwtSettings jwtSettings)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _tokenGenerator = tokenGenerator;
        _jwtTokenGenerator = jwtTokenGenerator;
        _emailService = emailService;
        _jwtSettings = jwtSettings;
    }

    public async Task<RegisterResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        var rol = ParseRol(request.Rol);
        var email = NormalizeEmail(request.Email);

        var existing = await _unitOfWork.Users.GetByEmailAsync(email, cancellationToken);
        if (existing is not null)
        {
            throw new ConflictException("El email ya está registrado.");
        }

        var user = new User
        {
            Nombre = request.Nombre.Trim(),
            Email = email,
            PasswordHash = _passwordHasher.Hash(request.Password),
            Telefono = string.IsNullOrWhiteSpace(request.Telefono) ? null : request.Telefono.Trim(),
            Rol = rol,
            Activo = true
        };

        await _unitOfWork.Users.AddAsync(user, cancellationToken);

        if (rol == UserRole.Repartidor)
        {
            await _unitOfWork.DeliveryPeople.AddAsync(
                new DeliveryPerson { UsuarioId = user.Id, EstadoDisponibilidad = DeliveryPersonStatus.Inactivo },
                cancellationToken);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        await _emailService.SendWelcomeEmailAsync(user.Email, user.Nombre, cancellationToken);

        return new RegisterResponse
        {
            Id = user.Id,
            Nombre = user.Nombre,
            Email = user.Email,
            Rol = UserRoleNames.From(rol),
            CreadoEn = user.CreadoEn
        };
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, ClientInfo client, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByEmailAsync(NormalizeEmail(request.Email), cancellationToken);
        if (user is null)
        {
            throw new UnauthorizedException("Email o contraseña incorrectos.");
        }

        if (!user.Activo)
        {
            throw new ForbiddenException("La cuenta está deshabilitada.");
        }

        if (user.BloqueadoHasta is { } bloqueadoHasta && bloqueadoHasta > DateTime.UtcNow)
        {
            throw new ForbiddenException("La cuenta está bloqueada temporalmente. Intente de nuevo más tarde.");
        }

        if (!_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            await RegisterFailedAttemptAsync(user, cancellationToken);
            throw new UnauthorizedException("Email o contraseña incorrectos.");
        }

        user.IntentosFallidos = 0;
        user.BloqueadoHasta = null;
        user.UltimoLogin = DateTime.UtcNow;
        _unitOfWork.Users.Update(user);

        var accessToken = _jwtTokenGenerator.GenerateAccessToken(user);
        var refreshToken = await IssueRefreshTokenAsync(user.Id, client, cancellationToken);

        await _unitOfWork.Audits.AddAsync(new AuditAction
        {
            UsuarioId = user.Id,
            Accion = "login",
            Entidad = "sesion",
            EntidadId = user.Id,
            IpOrigen = client.IpOrigen,
            UserAgent = client.UserAgent,
            CreadoEn = DateTime.UtcNow
        }, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new AuthResponse
        {
            AccessToken = accessToken.Value,
            RefreshToken = refreshToken,
            ExpiresIn = ToExpiresIn(accessToken.ExpiraEn),
            User = ToSummary(user)
        };
    }

    public async Task<RefreshResponse> RefreshAsync(RefreshRequest request, ClientInfo client, CancellationToken cancellationToken = default)
    {
        var stored = await GetValidRefreshTokenAsync(request.RefreshToken, cancellationToken);

        var user = await _unitOfWork.Users.GetByIdAsync(stored.UsuarioId, cancellationToken);
        if (user is null || !user.Activo)
        {
            throw new UnauthorizedException("Email o contraseña incorrectos.");
        }

        stored.Revocado = true;

        var accessToken = _jwtTokenGenerator.GenerateAccessToken(user);
        var refreshToken = await IssueRefreshTokenAsync(user.Id, client, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new RefreshResponse
        {
            AccessToken = accessToken.Value,
            RefreshToken = refreshToken,
            ExpiresIn = ToExpiresIn(accessToken.ExpiraEn)
        };
    }

    public async Task LogoutAsync(LogoutRequest request, CancellationToken cancellationToken = default)
    {
        var hash = _tokenGenerator.Hash(request.RefreshToken);
        var stored = await _unitOfWork.Users.GetRefreshTokenByHashAsync(hash, cancellationToken);
        if (stored is null || stored.Revocado)
        {
            return;
        }

        stored.Revocado = true;
        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }

    public async Task<MessageResponse> ForgotPasswordAsync(ForgotPasswordRequest request, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByEmailAsync(NormalizeEmail(request.Email), cancellationToken);
        if (user is not null && user.Activo)
        {
            var rawToken = _tokenGenerator.Generate();
            var resetToken = new PasswordResetToken
            {
                UsuarioId = user.Id,
                TokenHash = _tokenGenerator.Hash(rawToken),
                ExpiraEn = DateTime.UtcNow.AddHours(ResetTokenHours),
                Usado = false
            };

            await _unitOfWork.Users.AddPasswordResetTokenAsync(resetToken, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            await _emailService.SendPasswordResetEmailAsync(user.Email, user.Nombre, rawToken, cancellationToken);
        }

        return new MessageResponse(GenericForgotMessage);
    }

    public async Task<MessageResponse> ResetPasswordAsync(ResetPasswordRequest request, CancellationToken cancellationToken = default)
    {
        var hash = _tokenGenerator.Hash(request.Token);
        var resetToken = await _unitOfWork.Users.GetPasswordResetTokenByHashAsync(hash, cancellationToken);
        if (resetToken is null || resetToken.Usado || resetToken.ExpiraEn <= DateTime.UtcNow)
        {
            throw new ValidationException("token", "El token es inválido o ha expirado.");
        }

        var user = await _unitOfWork.Users.GetByIdAsync(resetToken.UsuarioId, cancellationToken);
        if (user is null)
        {
            throw new ValidationException("token", "El token es inválido o ha expirado.");
        }

        user.PasswordHash = _passwordHasher.Hash(request.NewPassword);
        user.IntentosFallidos = 0;
        user.BloqueadoHasta = null;
        resetToken.Usado = true;
        _unitOfWork.Users.Update(user);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new MessageResponse("Contraseña restablecida correctamente.");
    }

    private async Task RegisterFailedAttemptAsync(User user, CancellationToken cancellationToken)
    {
        user.IntentosFallidos++;

        if (user.IntentosFallidos >= MaxFailedAttempts)
        {
            user.IntentosFallidos = 0;
            user.BloqueadoHasta = DateTime.UtcNow.AddMinutes(LockoutMinutes);
        }

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }

    private async Task<RefreshToken> GetValidRefreshTokenAsync(string rawToken, CancellationToken cancellationToken)
    {
        var hash = _tokenGenerator.Hash(rawToken);
        var stored = await _unitOfWork.Users.GetRefreshTokenByHashAsync(hash, cancellationToken);
        if (stored is null || stored.Revocado || stored.ExpiraEn <= DateTime.UtcNow)
        {
            throw new ValidationException("refreshToken", "El token de refresco es inválido, expirado o revocado.");
        }

        return stored;
    }

    private async Task<string> IssueRefreshTokenAsync(Guid userId, ClientInfo client, CancellationToken cancellationToken)
    {
        var rawToken = _tokenGenerator.Generate();
        var refreshToken = new RefreshToken
        {
            UsuarioId = userId,
            TokenHash = _tokenGenerator.Hash(rawToken),
            ExpiraEn = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpirationDays),
            Revocado = false,
            IpOrigen = client.IpOrigen,
            UserAgent = client.UserAgent
        };

        await _unitOfWork.Users.AddRefreshTokenAsync(refreshToken, cancellationToken);
        return rawToken;
    }

    private static int ToExpiresIn(DateTime expiraEn)
    {
        var seconds = (int)Math.Max(0, (expiraEn - DateTime.UtcNow).TotalSeconds);
        return seconds;
    }

    private static UserSummaryDto ToSummary(User user)
    {
        return new UserSummaryDto
        {
            Id = user.Id,
            Nombre = user.Nombre,
            Email = user.Email,
            Rol = UserRoleNames.From(user.Rol)
        };
    }

    private static string NormalizeEmail(string email)
    {
        return email.Trim().ToLowerInvariant();
    }

    private static UserRole ParseRol(string rol)
    {
        return rol.Trim().ToLowerInvariant() switch
        {
            "cliente" => UserRole.Cliente,
            "administrador" => UserRole.Administrador,
            "repartidor" => UserRole.Repartidor,
            _ => throw new ValidationException("rol", "El rol debe ser cliente, administrador o repartidor.")
        };
    }
}
