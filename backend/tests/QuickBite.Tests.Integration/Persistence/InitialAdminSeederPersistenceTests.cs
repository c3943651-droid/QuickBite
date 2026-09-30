using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Infrastructure.Authentication;
using QuickBite.Infrastructure.Persistence;
using QuickBite.Infrastructure.Seeding;

namespace QuickBite.Tests.Integration.Persistence;

public class InitialAdminSeederPersistenceTests : PersistenceTestBase
{
    private static readonly Guid DemoAdminId = Guid.Parse("a0000000-0000-0000-0000-000000000001");

    public InitialAdminSeederPersistenceTests(PostgresDatabaseFixture db) : base(db)
    {
    }

    private static InitialAdminSeeder CreateSeeder(QuickBiteDbContext dbContext) =>
        new(dbContext, new BcryptPasswordHasher(), NullLogger<InitialAdminSeeder>.Instance);

    [Fact]
    public async Task Seed_CreaAdministradorConPasswordEncriptada()
    {
        if (!CanRun())
        {
            return;
        }

        var email = $"real-admin-{Guid.NewGuid():N}@quickbite.local";
        const string password = "Clave-Segura-123";

        await using var dbContext = Db.CreateContext();
        var seeder = CreateSeeder(dbContext);

        try
        {
            var creados = await seeder.SeedAsync(email, password);

            creados.Should().Be(1);

            var usuario = await dbContext.Usuarios.SingleAsync(u => u.Email == email);
            usuario.Rol.Should().Be(UserRole.Administrador);
            usuario.Activo.Should().BeTrue();
            usuario.PasswordHash.Should().StartWith("$2a$12$");
            new BcryptPasswordHasher().Verify(password, usuario.PasswordHash).Should().BeTrue();
            new BcryptPasswordHasher().Verify("Clave-Incorrecta", usuario.PasswordHash).Should().BeFalse();

            var segundaEjecucion = await seeder.SeedAsync(email, password);
            segundaEjecucion.Should().Be(0);
            (await dbContext.Usuarios.CountAsync(u => u.Email == email)).Should().Be(1);
        }
        finally
        {
            await dbContext.Usuarios.Where(u => u.Email == email).ExecuteDeleteAsync();
        }
    }

    [Fact]
    public async Task Seed_OmiteCuandoExisteAdministradorActivo()
    {
        if (!CanRun())
        {
            return;
        }

        const string email = "admin-activo-existente@quickbite.local";

        await using var dbContext = Db.CreateContext();

        var adminDemo = await dbContext.Usuarios.SingleAsync(u => u.Id == DemoAdminId);
        var activoOriginal = adminDemo.Activo;
        adminDemo.Activo = true;
        await dbContext.SaveChangesAsync();

        try
        {
            var creados = await CreateSeeder(dbContext).SeedAsync(email, "Clave-Segura-123");

            creados.Should().Be(0);
            (await dbContext.Usuarios.AnyAsync(u => u.Email == email)).Should().BeFalse();
        }
        finally
        {
            adminDemo.Activo = activoOriginal;
            await dbContext.SaveChangesAsync();
            await dbContext.Usuarios.Where(u => u.Email == email).ExecuteDeleteAsync();
        }
    }

    [Fact]
    public async Task Seed_OmiteSiElEmailYaExisteSinRolAdministrador()
    {
        if (!CanRun())
        {
            return;
        }

        var email = $"ya-registrado-{Guid.NewGuid():N}@quickbite.local";

        await using var dbContext = Db.CreateContext();

        dbContext.Usuarios.Add(new User
        {
            Nombre = "Cliente",
            Email = email,
            PasswordHash = new BcryptPasswordHasher().Hash("Clave-Cliente-123"),
            Rol = UserRole.Cliente
        });
        await dbContext.SaveChangesAsync();

        try
        {
            var creados = await CreateSeeder(dbContext).SeedAsync(email, "Clave-Segura-123");

            creados.Should().Be(0);
            var usuario = await dbContext.Usuarios.SingleAsync(u => u.Email == email);
            usuario.Rol.Should().Be(UserRole.Cliente);
        }
        finally
        {
            await dbContext.Usuarios.Where(u => u.Email == email).ExecuteDeleteAsync();
        }
    }

    [Fact]
    public async Task Seed_ConPasswordCorta_NoCreaCuenta()
    {
        if (!CanRun())
        {
            return;
        }

        var email = $"password-corta-{Guid.NewGuid():N}@quickbite.local";

        await using var dbContext = Db.CreateContext();

        try
        {
            var seeder = CreateSeeder(dbContext);

            var act = () => seeder.SeedAsync(email, "1234567");
            await act.Should().ThrowAsync<InvalidOperationException>();

            (await dbContext.Usuarios.AnyAsync(u => u.Email == email)).Should().BeFalse();
        }
        finally
        {
            await dbContext.Usuarios.Where(u => u.Email == email).ExecuteDeleteAsync();
        }
    }
}