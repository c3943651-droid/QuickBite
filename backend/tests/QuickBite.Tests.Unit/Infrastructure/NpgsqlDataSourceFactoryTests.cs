using FluentAssertions;
using Npgsql;
using QuickBite.Infrastructure.Persistence;

namespace QuickBite.Tests.Unit.Infrastructure;

public class NpgsqlDataSourceFactoryTests
{
    private const string BaseConnection =
        "Host=localhost;Database=quickbite;Username=postgres;Password=postgres;SSL Mode=Require";

    [Fact]
    public void Create_SinLimiteConfigurado_LimitaElPoolPorDebajoDelPoolerDeSupabase()
    {
        using var dataSource = NpgsqlDataSourceFactory.Create(BaseConnection);

        var csb = new NpgsqlConnectionStringBuilder(dataSource.ConnectionString);

        csb.MaxPoolSize.Should().Be(6);
        csb.ConnectionIdleLifetime.Should().Be(60);
    }

    [Fact]
    public void Create_ConLimitesExplicitos_LosRespeta()
    {
        using var dataSource = NpgsqlDataSourceFactory.Create(
            $"{BaseConnection};Maximum Pool Size=3;Connection Idle Lifetime=15");

        var csb = new NpgsqlConnectionStringBuilder(dataSource.ConnectionString);

        csb.MaxPoolSize.Should().Be(3);
        csb.ConnectionIdleLifetime.Should().Be(15);
    }
}
