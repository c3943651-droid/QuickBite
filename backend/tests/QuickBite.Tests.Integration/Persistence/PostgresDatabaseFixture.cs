using Microsoft.EntityFrameworkCore;
using Npgsql;
using QuickBite.Infrastructure.Persistence;
using Testcontainers.PostgreSql;

namespace QuickBite.Tests.Integration.Persistence;

public class PostgresDatabaseFixture : IAsyncLifetime
{
    private PostgreSqlContainer? _container;

    public bool Available { get; private set; }
    public string? ConnectionString { get; private set; }
    public string? SkipReason { get; private set; }

    public async Task InitializeAsync()
    {
        try
        {
            _container = new PostgreSqlBuilder()
                .WithImage("postgres:15-alpine")
                .WithDatabase("quickbite_test")
                .WithUsername("postgres")
                .WithPassword("postgres")
                .Build();

            await _container.StartAsync();

            ConnectionString = _container.GetConnectionString();
            Available = true;

            using var dbContext = CreateContext();
            await dbContext.Database.MigrateAsync();
        }
        catch (Exception exception)
        {
            Available = false;
            SkipReason = $"PostgreSQL (Testcontainers/Docker) no disponible, tests omitidos: {exception.Message}";

            if (_container is not null)
            {
                try
                {
                    await _container.DisposeAsync();
                }
                catch
                {
                    // noop
                }

                _container = null;
            }
        }
    }

    public QuickBiteDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<QuickBiteDbContext>()
            .UseNpgsql(ConnectionString!, npgsql => npgsql.EnableRetryOnFailure())
            .UseSnakeCaseNamingConvention()
            .Options;

        return new QuickBiteDbContext(options);
    }

    public async Task DisposeAsync()
    {
        if (_container is not null)
        {
            await _container.DisposeAsync();
        }
    }
}