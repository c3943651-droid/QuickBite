using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using QuickBite.Application.Admin;
using QuickBite.Application.Delivery;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Infrastructure.Persistence;
using QuickBite.Infrastructure.Persistence.Repositories;

namespace QuickBite.Tests.Integration.Persistence;

/// <summary>
/// Cubre la liberación automática del repartidor: al cerrar el pedido como
/// entregado o cancelado, debe volver a <c>Disponible</c> para que la modal de
/// asignación del panel admin deje de mostrar "Sin repartidores disponibles".
/// </summary>
public class DeliveryPersonReleaseTests : PersistenceTestBase
{
    public DeliveryPersonReleaseTests(PostgresDatabaseFixture db) : base(db)
    {
    }

    private static async Task<Guid> CrearClienteAsync(QuickBiteDbContext dbContext)
    {
        var user = new User
        {
            Nombre = "Cliente Liberation",
            Email = $"liberacion-cliente{Guid.NewGuid():N}@test.com",
            Rol = UserRole.Cliente
        };

        dbContext.Usuarios.Add(user);
        await dbContext.SaveChangesAsync();

        return user.Id;
    }

    private static async Task<Guid> CrearRepartidorAsync(QuickBiteDbContext dbContext, DeliveryPersonStatus estado)
    {
        var usuario = new User
        {
            Nombre = "Repartidor Liberation",
            Email = $"liberacion-repartidor{Guid.NewGuid():N}@test.com",
            Rol = UserRole.Repartidor
        };

        dbContext.Usuarios.Add(usuario);
        await dbContext.SaveChangesAsync();

        dbContext.Repartidores.Add(new DeliveryPerson
        {
            UsuarioId = usuario.Id,
            EstadoDisponibilidad = estado,
            Vehiculo = "Moto",
            FechaAlta = DateTime.UtcNow
        });
        await dbContext.SaveChangesAsync();

        return usuario.Id;
    }

    private static async Task<Order> CrearPedidoAsync(
        QuickBiteDbContext dbContext,
        Guid clienteId,
        Guid? repartidorId,
        OrderStatus estado)
    {
        var order = new Order
        {
            Id = Guid.NewGuid(),
            ClienteId = clienteId,
            RepartidorId = repartidorId,
            NumeroPedido = $"LIB-{Guid.NewGuid():N}"[..20],
            Subtotal = 100m,
            CostoEnvio = 0m,
            Total = 100m,
            Estado = estado,
            MetodoPago = PaymentMethodType.Efectivo,
            DireccionEntregaSnapshot = "Calle de prueba 456"
        };

        dbContext.Pedidos.Add(order);
        await dbContext.SaveChangesAsync();

        return order;
    }

    private async Task<DeliveryPersonStatus> LeerEstadoAsync(Guid repartidorId)
    {
        await using var reader = Db.CreateContext();
        var repartidor = await reader.Repartidores
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.UsuarioId == repartidorId);

        repartidor.Should().NotBeNull();
        return repartidor!.EstadoDisponibilidad;
    }

    [Fact]
    public async Task CicloCompleto_AsignarEntregarYLiberarRepartidor()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var clienteId = await CrearClienteAsync(dbContext);
        var repartidorId = await CrearRepartidorAsync(dbContext, DeliveryPersonStatus.Disponible);
        var pedido = await CrearPedidoAsync(dbContext, clienteId, null, OrderStatus.Listo);

        var repository = new OrderRepository(dbContext);

        // 1. Asignar el pedido deja al repartidor ocupado. La asignación se
        //    guarda antes de mover el estado porque el trigger
        //    trg_validar_asignacion_repartidor solo admite cambiar
        //    repartidor_id con el pedido en 'listo'.
        await repository.AssignDeliveryPersonAsync(pedido.Id, repartidorId, AssignmentOrigin.Assisted);
        await dbContext.SaveChangesAsync();

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Ocupado);

        await repository.UpdateStatusAsync(pedido.Id, OrderStatus.EnCamino);
        await dbContext.SaveChangesAsync();

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Ocupado);

        // 2. Completar la entrega debe liberar al repartidor.
        await repository.UpdateStatusAsync(pedido.Id, OrderStatus.Entregado);
        await dbContext.SaveChangesAsync();

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Disponible);

        // 3. Y debe volver a aparecer en el listado de repartidores disponibles
        //    que consume la modal "Asignar repartidor".
        await using var reader = Db.CreateContext();
        var disponibles = await new DeliveryPersonRepository(reader)
            .GetPagedAsync(DeliveryPersonStatus.Disponible, 1, 100);

        disponibles.Items.Should().ContainSingle(r => r.UsuarioId == repartidorId);
    }

    [Fact]
    public async Task CancelarPedidoEnCamino_LiberaAlRepartidor()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var clienteId = await CrearClienteAsync(dbContext);
        var repartidorId = await CrearRepartidorAsync(dbContext, DeliveryPersonStatus.Ocupado);
        var pedido = await CrearPedidoAsync(dbContext, clienteId, repartidorId, OrderStatus.EnCamino);

        var repository = new OrderRepository(dbContext);

        await repository.CancelOrderAsync(pedido.Id, "Cliente ausente");
        await dbContext.SaveChangesAsync();

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Disponible);
    }

    [Fact]
    public async Task RepartidorConOtroPedidoEnCamino_NoSeLiberaAlEntregarUno()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var clienteId = await CrearClienteAsync(dbContext);
        var repartidorId = await CrearRepartidorAsync(dbContext, DeliveryPersonStatus.Ocupado);

        var entregado = await CrearPedidoAsync(dbContext, clienteId, repartidorId, OrderStatus.EnCamino);
        await CrearPedidoAsync(dbContext, clienteId, repartidorId, OrderStatus.EnCamino);

        var repository = new OrderRepository(dbContext);

        await repository.UpdateStatusAsync(entregado.Id, OrderStatus.Entregado);
        await dbContext.SaveChangesAsync();

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Ocupado);
        (await repository.HasActiveOrdersAsync(repartidorId)).Should().BeTrue();
    }

    [Fact]
    public async Task EntregarUltimoPedidoEnCamino_LiberaAlRepartidor()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var clienteId = await CrearClienteAsync(dbContext);
        var repartidorId = await CrearRepartidorAsync(dbContext, DeliveryPersonStatus.Ocupado);

        var primero = await CrearPedidoAsync(dbContext, clienteId, repartidorId, OrderStatus.EnCamino);
        var segundo = await CrearPedidoAsync(dbContext, clienteId, repartidorId, OrderStatus.EnCamino);

        var repository = new OrderRepository(dbContext);

        await repository.UpdateStatusAsync(primero.Id, OrderStatus.Entregado);
        await dbContext.SaveChangesAsync();

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Ocupado);

        await repository.UpdateStatusAsync(segundo.Id, OrderStatus.Entregado);
        await dbContext.SaveChangesAsync();

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Disponible);
        (await repository.HasActiveOrdersAsync(repartidorId)).Should().BeFalse();
    }

    [Fact]
    public async Task PedidoSinRepartidor_NoIntentaLiberar()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var clienteId = await CrearClienteAsync(dbContext);
        var pedido = await CrearPedidoAsync(dbContext, clienteId, null, OrderStatus.Listo);

        var repository = new OrderRepository(dbContext);

        var act = async () =>
        {
            await repository.UpdateStatusAsync(pedido.Id, OrderStatus.Entregado);
            await dbContext.SaveChangesAsync();
        };

        await act.Should().NotThrowAsync();
    }

    [Fact]
    public async Task RepartidorInactivo_NoSeMarcaDisponibleAutomaticamente()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();
        var clienteId = await CrearClienteAsync(dbContext);
        var repartidorId = await CrearRepartidorAsync(dbContext, DeliveryPersonStatus.Inactivo);
        var pedido = await CrearPedidoAsync(dbContext, clienteId, repartidorId, OrderStatus.EnCamino);

        var repository = new OrderRepository(dbContext);

        await repository.UpdateStatusAsync(pedido.Id, OrderStatus.Entregado);
        await dbContext.SaveChangesAsync();

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Inactivo);
    }

    /// <summary>
    /// Recorre el flujo real de los servicios (asignar desde el panel admin y
    /// completar desde el móvil) contra PostgreSQL. Cubre de paso el orden de
    /// guardado que exige el trigger trg_validar_asignacion_repartidor.
    /// </summary>
    [Fact]
    public async Task FlujoDeServicios_AsignarYCompletarLiberaAlRepartidor()
    {
        if (!CanRun())
        {
            return;
        }

        Guid clienteId;
        Guid repartidorId;
        Guid pedidoId;

        await using (var dbContext = Db.CreateContext())
        {
            clienteId = await CrearClienteAsync(dbContext);
            repartidorId = await CrearRepartidorAsync(dbContext, DeliveryPersonStatus.Disponible);

            var pedido = await CrearPedidoAsync(dbContext, clienteId, null, OrderStatus.Listo);
            pedidoId = pedido.Id;
        }

        // Asignar desde el panel admin.
        await using (var dbContext = Db.CreateContext())
        {
            var service = new AdminOrderService(new UnitOfWork(dbContext));
            await service.AssignAsync(pedidoId, repartidorId, AssignmentOrigin.Assisted);
        }

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Ocupado);

        await using (var reader = Db.CreateContext())
        {
            var pedido = await new OrderRepository(reader).GetByIdAsync(pedidoId);
            pedido.Should().NotBeNull();
            pedido!.Estado.Should().Be(OrderStatus.EnCamino);
        }

        // Completar la entrega desde el móvil del repartidor.
        await using (var dbContext = Db.CreateContext())
        {
            var service = new DeliveryService(new UnitOfWork(dbContext));
            await service.CompleteAsync(repartidorId, pedidoId);
        }

        (await LeerEstadoAsync(repartidorId)).Should().Be(DeliveryPersonStatus.Disponible);
    }
}
