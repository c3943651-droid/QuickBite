using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using QuickBite.Application.Catalog;
using QuickBite.Application.Catalog.Dtos;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;
using QuickBite.Infrastructure.Persistence.Repositories;
using Xunit.Abstractions;

namespace QuickBite.Tests.Integration.Persistence;

public class CatalogProductPersistenceTests : PersistenceTestBase
{
    private static readonly Guid CategoriaHamburguesasId = Guid.Parse("b0000000-0000-0000-0000-000000000001");

    private const string PrefijoUrlSupabase =
        "https://zkueflkfkvrhyqxobrrm.supabase.co/storage/v1/object/public/catalog-images/";

    private static int _userCounter;
    private readonly ITestOutputHelper _output;

    public CatalogProductPersistenceTests(PostgresDatabaseFixture db, ITestOutputHelper output) : base(db)
    {
        _output = output;
    }

    [Fact]
    public async Task CatalogService_CreaYActualizaProductoConImagenDeSupabase()
    {
        if (!CanRun())
        {
            return;
        }

        Guid productId = default;
        Guid adminId = default;
        try
        {
            await using var dbContext = Db.CreateContext();
            var unitOfWork = new UnitOfWork(dbContext);
            var service = new CatalogService(unitOfWork, new NoOpImageService());

            var admin = new User
            {
                Nombre = "Admin Reproduccion",
                Email = $"admin-repro{System.Threading.Interlocked.Increment(ref _userCounter)}@test.com",
                Rol = UserRole.Administrador
            };
            dbContext.Usuarios.Add(admin);
            await dbContext.SaveChangesAsync();
            adminId = admin.Id;

            var imagenUrl = $"{PrefijoUrlSupabase}{Guid.NewGuid():N}.jpg";
            imagenUrl.Length.Should().BeLessThanOrEqualTo(500);

            var created = await service.CreateProductAsync(new CreateProductRequest
            {
                Nombre = "Combo Reproduccion Produccion",
                Descripcion = "Reproduce el guardado del panel admin",
                Precio = 99.99m,
                CategoriaId = CategoriaHamburguesasId,
                ImagenUrl = imagenUrl,
                Disponible = true,
                StockInicial = 10,
                StockMinimo = 2
            }, admin.Id);
            productId = created.Id;

            created.Should().NotBeNull();
            created.Nombre.Should().Be("Combo Reproduccion Produccion");
            created.Precio.Should().Be(99.99m);
            created.ImagenUrl.Should().Be(imagenUrl);
            created.Stock.Should().Be(10);
            created.Disponible.Should().BeTrue();

            var imagenUrlNueva = $"{PrefijoUrlSupabase}{Guid.NewGuid():N}.jpg";

            ProductDetailResponse updated;
            try
            {
                updated = await service.UpdateProductAsync(created.Id, new UpdateProductRequest
                {
                    Nombre = "Combo Reproduccion Produccion v2",
                    Precio = 109.99m,
                    ImagenUrl = imagenUrlNueva,
                    Disponible = false
                }, admin.Id);
            }
            catch (DbUpdateConcurrencyException exception)
            {
                var detail = string.Join("\n---\n", exception.Entries.Select(entry =>
                    $"{entry.Metadata.Name}\n" +
                    string.Join("\n", entry.Properties
                        .Where(p => p.IsModified)
                        .Select(p => $"  {p.Metadata.Name}: original={p.OriginalValue ?? "null"} -> actual={p.CurrentValue ?? "null"}"))));
                var inner = exception.InnerException?.Message ?? string.Empty;
                _output.WriteLine($"DbUpdateConcurrencyException. Entradas: {detail}\nInner: {inner}");
                throw new Xunit.Sdk.XunitException(
                    $"DbUpdateConcurrencyException al actualizar producto.\n{detail}\nInner: {inner}\n",
                    exception);
            }

            updated.Should().NotBeNull();
            updated.Nombre.Should().Be("Combo Reproduccion Produccion v2");
            updated.Precio.Should().Be(109.99m);
            updated.ImagenUrl.Should().Be(imagenUrlNueva);
            updated.Disponible.Should().BeFalse();

            await using var reader = Db.CreateContext();
            var persisted = await new ProductRepository(reader).GetByIdAsync(created.Id);
            persisted.Should().NotBeNull();
            persisted!.Nombre.Should().Be("Combo Reproduccion Produccion v2");
            persisted.ImagenUrl.Should().Be(imagenUrlNueva);
            persisted.Inventario.Should().NotBeNull();
            persisted.Inventario!.Stock.Should().Be(10);
            persisted.Inventario.StockMinimo.Should().Be(2);
            persisted.PreciosHistoricos.Should().ContainSingle(h =>
                h.PrecioAnterior == 99.99m && h.PrecioNuevo == 109.99m && h.UsuarioId == admin.Id);
        }
        finally
        {
            await LimpiarProductoYUsuarioAsync(productId, adminId);
        }
    }

    private async Task LimpiarProductoYUsuarioAsync(Guid productId, Guid adminId)
    {
        if (productId == default && adminId == default)
        {
            return;
        }

        await using var cleaner = Db.CreateContext();
        if (productId != default)
        {
            await cleaner.ProductosPreciosHistoricos
                .Where(h => h.ProductoId == productId)
                .ExecuteDeleteAsync();
            await cleaner.Inventario
                .Where(i => i.ProductoId == productId)
                .ExecuteDeleteAsync();
            await cleaner.Productos
                .Where(p => p.Id == productId)
                .ExecuteDeleteAsync();
        }

        if (adminId != default)
        {
            await cleaner.Usuarios
                .Where(u => u.Id == adminId)
                .ExecuteDeleteAsync();
        }
    }

    private sealed class NoOpImageService : IImageService
    {
        public Task<string> UploadAsync(Stream stream, string fileName, CancellationToken ct = default)
            => Task.FromResult("https://ejemplo.test/imagen.jpg");

        public Task DeleteAsync(string url, CancellationToken ct = default) => Task.CompletedTask;
    }
}