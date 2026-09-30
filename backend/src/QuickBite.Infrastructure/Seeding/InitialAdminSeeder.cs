using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using QuickBite.Application.Authentication;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Infrastructure.Seeding;

public sealed class InitialAdminSeeder : IInitialAdminSeeder
{
    private readonly QuickBiteDbContext _db;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ILogger<InitialAdminSeeder> _logger;

    public InitialAdminSeeder(
        QuickBiteDbContext db,
        IPasswordHasher passwordHasher,
        ILogger<InitialAdminSeeder> logger)
    {
        _db = db;
        _passwordHasher = passwordHasher;
        _logger = logger;
    }

    public async Task<int> SeedAsync(
        string? adminEmail,
        string? adminPassword,
        CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(adminEmail) || string.IsNullOrWhiteSpace(adminPassword))
        {
            _logger.LogInformation("ADMIN_EMAIL/ADMIN_PASSWORD no definidas; no se crea cuenta de administrador inicial.");
            return 0;
        }

        if (adminPassword.Length < 8)
        {
            throw new InvalidOperationException("ADMIN_PASSWORD debe tener al menos 8 caracteres.");
        }

        var email = adminEmail.Trim();

        var existeAdminActivo = await _db.Usuarios.AnyAsync(
            u => u.Rol == UserRole.Administrador && u.Activo,
            cancellationToken);
        if (existeAdminActivo)
        {
            _logger.LogInformation("Ya existe un administrador activo; se omite la creación inicial.");
            return 0;
        }

        if (await _db.Usuarios.AnyAsync(u => u.Email == email, cancellationToken))
        {
            _logger.LogWarning("El email {AdminEmail} ya está registrado sin rol administrador; no se crea la cuenta.", email);
            return 0;
        }

        _db.Usuarios.Add(new User
        {
            Nombre = "Administrador",
            Email = email,
            PasswordHash = _passwordHasher.Hash(adminPassword),
            Rol = UserRole.Administrador
        });

        await _db.SaveChangesAsync(cancellationToken);
        _logger.LogInformation("Cuenta de administrador inicial creada para {AdminEmail}.", email);
        return 1;
    }
}