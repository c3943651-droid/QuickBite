using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Npgsql.EntityFrameworkCore.PostgreSQL;

namespace QuickBite.Infrastructure.Persistence;

public class QuickBiteDbContextFactory : IDesignTimeDbContextFactory<QuickBiteDbContext>
{
    public QuickBiteDbContext CreateDbContext(string[] args)
    {
        var connectionString =
            Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection")
            ?? "Host=localhost;Database=quickbite;Username=postgres;Password=postgres";

        var options = new DbContextOptionsBuilder<QuickBiteDbContext>()
            .UseNpgsql(connectionString)
            .UseSnakeCaseNamingConvention()
            .Options;

        return new QuickBiteDbContext(options);
    }
}