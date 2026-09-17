using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories.Models;
using QuickBite.Infrastructure.Persistence;
using QuickBite.Infrastructure.Persistence.Repositories;

namespace QuickBite.Tests.Integration.Persistence;

public class RepositoryIntegrationTests : PersistenceTestBase
{
    private static readonly Guid CategoriaHamburguesasId = Guid.Parse("b0000000-0000-0000-0000-000000000001");
    private static readonly Guid ProductoClasicaId = Guid.Parse("c0000000-0000-0000-0000-000000000001");
    private static readonly Guid RepartidorSeedId = Guid.Parse("a0000000-0000-0000-0000-000000000002");

    private static int _userCounter;

    public RepositoryIntegrationTests(PostgresDatabaseFixture db) : base(db)
    {
    }

    private static async Task<Guid> CrearClienteAsync(QuickBiteDbContext dbContext)
    {
        var email = $"cliente{System.Threading.Interlocked.Increment(ref _userCounter)}@test.com";
        var user = new User
        {
            Nombre = "Cliente Test",
            Email = email,
            Rol = UserRole.Cliente
        };

        dbContext.Usuarios.Add(user);
        await dbContext.SaveChangesAsync();

        return user.Id;
    }

    [Fact]
    public async Task UnitOfWork_GuardaYConsultaUsuario()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var unitOfWork = new UnitOfWork(dbContext);

        var user = new User
        {
            Nombre = "Usuario UoW",
            Email = $"uow{System.Threading.Interlocked.Increment(ref _userCounter)}@test.com",
            Rol = UserRole.Cliente
        };

        await unitOfWork.Users.AddAsync(user);
        (await unitOfWork.SaveChangesAsync()).Should().BeTrue();

        await using var reader = Db.CreateContext();
        var loaded = await new UserRepository(reader).GetByEmailAsync(user.Email);
        loaded.Should().NotBeNull();
        loaded!.Nombre.Should().Be("Usuario UoW");
    }

    [Fact]
    public async Task ProductRepository_PaginaYFiltra()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var repository = new ProductRepository(dbContext);

        var paged = await repository.GetPagedAsync(new ProductFilterParams
        {
            CategoryId = CategoriaHamburguesasId,
            Page = 1,
            PageSize = 2,
            SortBy = "precio",
            SortDescending = true
        });

        paged.TotalCount.Should().Be(3);
        paged.Items.Should().HaveCount(2);
        paged.Items[0].Nombre.Should().Be("Doble Carne");

        var search = await repository.GetPagedAsync(new ProductFilterParams { SearchTerm = "jugo" });
        search.TotalCount.Should().Be(1);
        search.Items[0].Nombre.Should().Be("Jugo Natural");

        var available = await repository.GetPagedAsync(new ProductFilterParams { OnlyAvailable = true, PageSize = 50 });
        available.TotalCount.Should().Be(7);

        var all = await repository.GetAllAsync(CategoriaHamburguesasId, true);
        all.Should().HaveCount(3);
    }

    [Fact]
    public async Task CartRepository_AgregaItemYVaciaCarrito()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var userId = await CrearClienteAsync(dbContext);

        var cart = new Cart
        {
            Id = Guid.NewGuid(),
            UsuarioId = userId,
            Estado = CartStatus.Activo
        };

        dbContext.Carritos.Add(cart);
        await dbContext.SaveChangesAsync();

        var repository = new CartRepository(dbContext);

        var active = await repository.GetActiveByUserIdAsync(userId);
        active.Should().NotBeNull();

        await repository.AddItemAsync(cart.Id, new CartItem
        {
            Id = Guid.NewGuid(),
            ProductoId = ProductoClasicaId,
            Cantidad = 2
        });
        await dbContext.SaveChangesAsync();

        var withItem = await repository.GetActiveByUserIdAsync(userId);
        withItem!.Items.Should().ContainSingle(i => i.ProductoId == ProductoClasicaId && i.Cantidad == 2);

        await repository.ClearCartAsync(cart.Id);
        await dbContext.SaveChangesAsync();

        var cleared = await repository.GetActiveByUserIdAsync(userId);
        cleared!.Items.Should().BeEmpty();
    }

    [Fact]
    public async Task OrderRepository_ActualizaEstadoYCancelaConHistorial()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var clientId = await CrearClienteAsync(dbContext);

        var order = new Order
        {
            Id = Guid.NewGuid(),
            ClienteId = clientId,
            NumeroPedido = "TEST-0001",
            Subtotal = 20m,
            CostoEnvio = 2m,
            Total = 22m,
            Estado = OrderStatus.Pendiente,
            MetodoPago = PaymentMethodType.Efectivo,
            DireccionEntregaSnapshot = "Calle de prueba 123"
        };

        var repository = new OrderRepository(dbContext);
        await repository.AddAsync(order);
        await dbContext.SaveChangesAsync();

        await repository.UpdateStatusAsync(order.Id, OrderStatus.Confirmado, "Inicio");
        await dbContext.SaveChangesAsync();

        await using var reader = Db.CreateContext();
        var readerRepository = new OrderRepository(reader);

        var confirmed = await readerRepository.GetByIdAsync(order.Id);
        confirmed.Should().NotBeNull();
        confirmed!.Estado.Should().Be(OrderStatus.Confirmado);
        confirmed.ConfirmadoEn.Should().NotBeNull();
        confirmed.HistorialEstados.Should().ContainSingle(h =>
            h.EstadoAnterior == OrderStatus.Pendiente &&
            h.EstadoNuevo == OrderStatus.Confirmado &&
            h.Comentario == "Inicio");

        await readerRepository.CancelOrderAsync(order.Id, "Cliente ausente");
        await reader.SaveChangesAsync();

        var cancelled = await readerRepository.GetByOrderNumberAsync("TEST-0001");
        cancelled.Should().NotBeNull();
        cancelled!.Estado.Should().Be(OrderStatus.Cancelado);
        cancelled.MotivoCancelacion.Should().Be("Cliente ausente");
        cancelled.HistorialEstados.Should().ContainSingle(h =>
            h.EstadoAnterior == OrderStatus.Confirmado &&
            h.EstadoNuevo == OrderStatus.Cancelado);
    }

    [Fact]
    public async Task AddressRepository_EstablecePredeterminada()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var userId = await CrearClienteAsync(dbContext);

        var first = new Address { Id = Guid.NewGuid(), UsuarioId = userId, Calle = "Calle A", Ciudad = "CDMX", EsPredeterminada = true };
        var second = new Address { Id = Guid.NewGuid(), UsuarioId = userId, Calle = "Calle B", Ciudad = "CDMX", EsPredeterminada = false };

        dbContext.Direcciones.AddRange(first, second);
        await dbContext.SaveChangesAsync();

        var repository = new AddressRepository(dbContext);
        await repository.SetDefaultAsync(second.Id, userId);
        await dbContext.SaveChangesAsync();

        await using var reader = Db.CreateContext();
        var addresses = await new AddressRepository(reader).GetByUserIdAsync(userId);

        addresses.Should().ContainSingle(a => a.EsPredeterminada);
        addresses.Single(a => a.EsPredeterminada).Id.Should().Be(second.Id);
    }

    [Fact]
    public async Task DeliveryPersonRepository_DevuelveEstadisticasEnCero()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var repository = new DeliveryPersonRepository(dbContext);

        var stats = await repository.GetStatsAsync(RepartidorSeedId);
        stats.Should().NotBeNull();
        stats!.DeliveryPersonId.Should().Be(RepartidorSeedId);
        stats.EntregasTotales.Should().Be(0);
        stats.EntregasDelMes.Should().Be(0);
        stats.TiempoPromedioEntregaMinutos.Should().Be(0);
        stats.Cancelaciones.Should().Be(0);

        var deliveryPerson = await repository.GetByIdAsync(RepartidorSeedId);
        deliveryPerson.Should().NotBeNull();
        deliveryPerson!.Usuario.Should().NotBeNull();
        deliveryPerson.Usuario!.Email.Should().Be("repartidor@quickbite.com");
    }

    [Fact]
    public async Task ConfigRepository_ActualizaYConsulta()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var repository = new ConfigRepository(dbContext);

        await repository.UpdateAsync("costo_envio_default", "3.50");
        await dbContext.SaveChangesAsync();

        await using var reader = Db.CreateContext();
        var readerRepository = new ConfigRepository(reader);

        var config = await readerRepository.GetByKeyAsync("COSTO_ENVIO_DEFAULT");
        config.Should().NotBeNull();
        config!.Valor.Should().Be("3.50");

        (await readerRepository.GetAllAsync()).Should().HaveCount(5);
    }

    [Fact]
    public async Task UserRepository_ListaYRevocaSesiones()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var userId = await CrearClienteAsync(dbContext);

        var active = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UsuarioId = userId,
            TokenHash = "hash-activo",
            ExpiraEn = DateTime.UtcNow.AddHours(1),
            IpOrigen = "10.0.0.1",
            UserAgent = "xunit"
        };

        var expired = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UsuarioId = userId,
            TokenHash = "hash-expirado",
            ExpiraEn = DateTime.UtcNow.AddHours(-1)
        };

        dbContext.TokensRefresco.AddRange(active, expired);
        await dbContext.SaveChangesAsync();

        var repository = new UserRepository(dbContext);

        var sessions = await repository.GetActiveSessionsAsync(userId);
        sessions.Should().ContainSingle();
        sessions.Single().SessionId.Should().Be(active.Id);
        sessions.Single().IpOrigen.Should().Be("10.0.0.1");

        (await repository.RevokeSessionAsync(active.Id, userId)).Should().BeTrue();
        await dbContext.SaveChangesAsync();

        (await repository.RevokeSessionAsync(active.Id, userId)).Should().BeFalse();

        var repartidores = await repository.GetByRoleAsync(UserRole.Repartidor);
        repartidores.Should().ContainSingle(r => r.Email == "repartidor@quickbite.com");
    }

    [Fact]
    public async Task NotificationRepository_MarcaLeidas()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var userId = await CrearClienteAsync(dbContext);
        var now = DateTime.UtcNow;

        dbContext.Notificaciones.AddRange(
            new Notification { Id = Guid.NewGuid(), UsuarioId = userId, Tipo = NotificationType.Sistema, Titulo = "Uno", Mensaje = "m1", CreadoEn = now },
            new Notification { Id = Guid.NewGuid(), UsuarioId = userId, Tipo = NotificationType.Sistema, Titulo = "Dos", Mensaje = "m2", CreadoEn = now.AddMinutes(-1) });
        await dbContext.SaveChangesAsync();

        var repository = new NotificationRepository(dbContext);

        var unread = await repository.GetByUserIdAsync(userId, unreadOnly: true);
        unread.Should().HaveCount(2);

        await repository.MarkAllAsReadAsync(userId);
        await dbContext.SaveChangesAsync();

        await using var reader = Db.CreateContext();
        var read = await new NotificationRepository(reader).GetByUserIdAsync(userId, unreadOnly: true);
        read.Should().BeEmpty();
    }

    [Fact]
    public async Task UserRepository_PersisteYBuscaTokensDeRefreshYRecuperacion()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var userId = await CrearClienteAsync(dbContext);
        var repository = new UserRepository(dbContext);

        var refresh = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UsuarioId = userId,
            TokenHash = "sha-refresh",
            ExpiraEn = DateTime.UtcNow.AddDays(7)
        };

        await repository.AddRefreshTokenAsync(refresh);
        await dbContext.SaveChangesAsync();

        await using var reader = Db.CreateContext();
        var readerRepository = new UserRepository(reader);

        var found = await readerRepository.GetRefreshTokenByHashAsync("sha-refresh");
        found.Should().NotBeNull();
        found!.UsuarioId.Should().Be(userId);
        found.Revocado.Should().BeFalse();
        (await readerRepository.GetRefreshTokenByHashAsync("no-existe")).Should().BeNull();

        var reset = new PasswordResetToken
        {
            Id = Guid.NewGuid(),
            UsuarioId = userId,
            TokenHash = "sha-reset",
            ExpiraEn = DateTime.UtcNow.AddHours(1)
        };

        await readerRepository.AddPasswordResetTokenAsync(reset);
        await reader.SaveChangesAsync();

        await using var secondReader = Db.CreateContext();
        var resetFound = await new UserRepository(secondReader).GetPasswordResetTokenByHashAsync("sha-reset");
        resetFound.Should().NotBeNull();
        resetFound!.UsuarioId.Should().Be(userId);
        resetFound.Usado.Should().BeFalse();
        (await new UserRepository(secondReader).GetPasswordResetTokenByHashAsync("no-existe")).Should().BeNull();
    }
}