using FluentAssertions;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Infrastructure.Persistence;
using QuickBite.Infrastructure.Persistence.Repositories;

namespace QuickBite.Tests.Integration.Persistence;

public class UserRepositoryPersistenceTests : PersistenceTestBase
{
    private static int _userCounter;

    public UserRepositoryPersistenceTests(PostgresDatabaseFixture db) : base(db)
    {
    }

    private static int NextCounter() => System.Threading.Interlocked.Increment(ref _userCounter);

    private static async Task<User> CrearUsuarioAsync(
        QuickBiteDbContext dbContext,
        string nombre,
        string email,
        UserRole rol,
        bool activo = true)
    {
        var user = new User
        {
            Nombre = nombre,
            Email = email,
            Rol = rol,
            Activo = activo
        };

        dbContext.Usuarios.Add(user);
        await dbContext.SaveChangesAsync();

        return user;
    }

    [Fact]
    public async Task GetPagedAsync_DevuelveUsuariosPaginaYFiltraPorRolYEstado()
    {
        if (!CanRun())
        {
            return;
        }

        var counter = NextCounter();
        await using var dbContext = Db.CreateContext();
        var repository = new UserRepository(dbContext);

        var clienteActivo = await CrearUsuarioAsync(dbContext, $"Cliente {counter}", $"cliente{counter}@test.com", UserRole.Cliente);
        var clienteInactivo = await CrearUsuarioAsync(dbContext, $"Cliente Inactivo {counter}", $"cliente-inactivo{counter}@test.com", UserRole.Cliente, activo: false);
        var admin = await CrearUsuarioAsync(dbContext, $"Admin {counter}", $"admin{counter}@test.com", UserRole.Administrador);

        try
        {
            var (clientesActivos, totalClientesActivos) = await repository.GetPagedAsync(null, UserRole.Cliente, true, 1, 10);
            totalClientesActivos.Should().BeGreaterThanOrEqualTo(1);
            clientesActivos.Should().Contain(u => u.Id == clienteActivo.Id);
            clientesActivos.Should().NotContain(u => u.Id == clienteInactivo.Id);

            var (admins, totalAdmins) = await repository.GetPagedAsync(null, UserRole.Administrador, null, 1, 10);
            totalAdmins.Should().BeGreaterThanOrEqualTo(1);
            admins.Should().Contain(u => u.Id == admin.Id);

            var (allClientes, totalClientes) = await repository.GetPagedAsync(null, UserRole.Cliente, null, 1, 10);
            totalClientes.Should().BeGreaterThanOrEqualTo(2);
        }
        finally
        {
            dbContext.Usuarios.RemoveRange(
                dbContext.Usuarios.Where(u => new[]
                {
                    clienteActivo.Id,
                    clienteInactivo.Id,
                    admin.Id
                }.Contains(u.Id)));
            await dbContext.SaveChangesAsync();
        }
    }

    [Fact]
    public async Task GetPagedAsync_BusquedaPorTextoYBusquedaIgnoraCase()
    {
        if (!CanRun())
        {
            return;
        }

        var counter = NextCounter();
        await using var dbContext = Db.CreateContext();
        var repository = new UserRepository(dbContext);

        var user = await CrearUsuarioAsync(dbContext, $"Busqueda {counter}", $"busqueda{counter}@test.com", UserRole.Cliente);

        try
        {
            var (byName, _) = await repository.GetPagedAsync($"Busqueda {counter}", null, null, 1, 10);
            byName.Should().Contain(u => u.Id == user.Id);

            var (byEmail, _) = await repository.GetPagedAsync($"BUSQUEDA{counter}", null, null, 1, 10);
            byEmail.Should().Contain(u => u.Id == user.Id);
        }
        finally
        {
            dbContext.Usuarios.Remove(dbContext.Usuarios.Find(user.Id)!);
            await dbContext.SaveChangesAsync();
        }
    }

    [Fact]
    public async Task GetPagedAsync_RespetaPaginacion()
    {
        if (!CanRun())
        {
            return;
        }

        var counter = NextCounter();
        await using var dbContext = Db.CreateContext();
        var repository = new UserRepository(dbContext);

        var created = new List<User>();
        try
        {
            for (var i = 0; i < 5; i++)
            {
                created.Add(await CrearUsuarioAsync(dbContext, $"Paginacion {counter} {i}", $"paginacion-{counter}-{i}@test.com", UserRole.Cliente));
            }

            var (pageOne, _) = await repository.GetPagedAsync($"Paginacion {counter}", null, null, 1, 2);
            pageOne.Count.Should().Be(2);

            var (pageTwo, _) = await repository.GetPagedAsync($"Paginacion {counter}", null, null, 2, 2);
            pageTwo.Count.Should().Be(2);

            var (pageThree, _) = await repository.GetPagedAsync($"Paginacion {counter}", null, null, 3, 2);
            pageThree.Count.Should().Be(1);
        }
        finally
        {
            dbContext.Usuarios.RemoveRange(
                dbContext.Usuarios.Where(u => created.Select(c => c.Id).Contains(u.Id)));
            await dbContext.SaveChangesAsync();
        }
    }
}