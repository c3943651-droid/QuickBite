using Microsoft.EntityFrameworkCore;
using Npgsql;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Tests.Integration.Persistence;

public class PostgresDatabaseFixture : IAsyncLifetime
{
    public bool Available { get; private set; }
    public string? ConnectionString { get; private set; }
    public string? SkipReason { get; private set; }

    public async Task InitializeAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__TestConnection")
            ?? Environment.GetEnvironmentVariable("ConnectionStrings__DefaultConnection");

        if (string.IsNullOrWhiteSpace(connectionString) || connectionString == "OVERRIDE_VIA_ENVIRONMENT_VARIABLE")
        {
            Available = false;
            SkipReason = "No hay PostgreSQL configurado: define ConnectionStrings__TestConnection (o ConnectionStrings__DefaultConnection). Tests omitidos.";
            return;
        }

        try
        {
            await using var probe = new NpgsqlConnection(connectionString);
            await probe.OpenAsync();

            await using var dbContext = CreateContext(connectionString);
            await dbContext.Database.MigrateAsync();

            ConnectionString = connectionString;
            Available = true;
        }
        catch (Exception exception)
        {
            Available = false;
            SkipReason = $"PostgreSQL no disponible, tests omitidos: {exception.Message}";
        }
    }

    public QuickBiteDbContext CreateContext(string? connectionString = null)
    {
        var options = new DbContextOptionsBuilder<QuickBiteDbContext>()
            .UseNpgsql(connectionString ?? ConnectionString!, npgsql => npgsql.EnableRetryOnFailure())
            .UseSnakeCaseNamingConvention()
            .Options;

        return new QuickBiteDbContext(options);
    }

    public Task DisposeAsync() => Task.CompletedTask;
}