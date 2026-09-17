using Microsoft.EntityFrameworkCore;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Tests.Integration.Persistence;

public class ModelTests
{
    [Fact]
    public void Model_TranslatesSpanishPostgresEnumWithoutDatabase()
    {
        var options = new DbContextOptionsBuilder<QuickBiteDbContext>()
            .UseNpgsql("Host=localhost;Database=model_tests;Username=model_tests")
            .Options;
        using var context = new QuickBiteDbContext(options);

        var sql = context.Set<Order>().Where(order => order.Estado == OrderStatus.EnCamino).ToQueryString();

        Assert.Contains("en_camino", sql);
        Assert.Contains("pedidos", sql);
        Assert.Contains("CREATE TYPE estado_pedido AS ENUM", context.Database.GenerateCreateScript());
    }
}
