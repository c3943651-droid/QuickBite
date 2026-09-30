using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Enums;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Tests.Integration.Persistence;

public class SeedDataIntegrationTests : PersistenceTestBase
{
    private static readonly Guid AdminId = Guid.Parse("a0000000-0000-0000-0000-000000000001");
    private static readonly Guid RepartidorId = Guid.Parse("a0000000-0000-0000-0000-000000000002");
    private static readonly Guid CategoriaHamburguesasId = Guid.Parse("b0000000-0000-0000-0000-000000000001");
    private static readonly Guid ProductoClasicaId = Guid.Parse("c0000000-0000-0000-0000-000000000001");
    private static readonly Guid ProductoDobleCarneId = Guid.Parse("c0000000-0000-0000-0000-000000000003");

    public SeedDataIntegrationTests(PostgresDatabaseFixture db) : base(db)
    {
    }

    [Fact]
    public async Task MigrationsSeed_ContieneCatalogosEsperados()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();

        (await dbContext.MetodosPago.CountAsync()).Should().Be(2);
        (await dbContext.ConfiguracionSistema.CountAsync()).Should().Be(10);
        (await dbContext.Categorias.CountAsync()).Should().Be(3);
        (await dbContext.Productos.CountAsync()).Should().Be(7);
        (await dbContext.Inventario.CountAsync()).Should().Be(7);
    }

    [Fact]
    public async Task MigrationsSeed_ConfiguracionSistemaIncluyeClavesOperativas()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();

        var porClave = await dbContext.ConfiguracionSistema
            .AsNoTracking()
            .ToDictionaryAsync(c => c.Clave);

        porClave.Should().ContainKeys(
            "restaurante_abierto",
            "horario_apertura",
            "horario_cierre",
            "moneda_simbolo",
            "moneda_codigo");

        porClave["restaurante_abierto"].Valor.Should().Be("true");
        porClave["horario_apertura"].Valor.Should().Be("08:00");
        porClave["horario_cierre"].Valor.Should().Be("22:00");
        porClave["moneda_simbolo"].Valor.Should().Be("$");
        porClave["moneda_codigo"].Valor.Should().Be("USD");
    }

    [Fact]
    public async Task MigrationsSeed_CredencialesDemoDesactivadas()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();

        var admin = await dbContext.Usuarios.SingleAsync(u => u.Id == AdminId);
        admin.Rol.Should().Be(UserRole.Administrador);
        admin.Activo.Should().BeFalse();
        admin.PasswordHash.Should().StartWith("$2b$12$");

        var repartidor = await dbContext.Repartidores.SingleAsync(r => r.UsuarioId == RepartidorId);
        repartidor.EstadoDisponibilidad.Should().Be(DeliveryPersonStatus.Disponible);
        repartidor.EntregasCompletadas.Should().Be(0);
    }

    [Fact]
    public async Task MigrationsSeed_CategoriasYProductosRelacionados()
    {
        if (!CanRun())
        {
            return;
        }

        await using var dbContext = Db.CreateContext();

        var hamburguesas = await dbContext.Categorias.SingleAsync(c => c.Id == CategoriaHamburguesasId);
        hamburguesas.Nombre.Should().Be("Hamburguesas");
        hamburguesas.Orden.Should().Be(1);

        var clasica = await dbContext.Productos.SingleAsync(p => p.Id == ProductoClasicaId);
        clasica.CategoriaId.Should().Be(CategoriaHamburguesasId);
        clasica.Disponible.Should().BeTrue();
        clasica.Precio.Should().Be(45.00m);

        var dobleCarne = await dbContext.Productos.SingleAsync(p => p.Id == ProductoDobleCarneId);
        dobleCarne.Precio.Should().Be(70.00m);
    }
}