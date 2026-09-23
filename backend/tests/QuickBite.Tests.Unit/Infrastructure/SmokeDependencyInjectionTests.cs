using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using QuickBite.Application;
using QuickBite.Infrastructure;

namespace QuickBite.Tests.Unit.Infrastructure;

public class SmokeDependencyInjectionTests
{
    private static IConfiguration BuildConfiguration()
    {
        var values = new Dictionary<string, string?>
        {
            ["ConnectionStrings:DefaultConnection"] = "Host=localhost;Database=quickbite_smoke;Username=postgres;Password=postgres",
            ["Jwt:Secret"] = "clave-super-secreta-para-smoke-tests-123456",
            ["Jwt:Issuer"] = "QuickBite",
            ["Jwt:Audience"] = "QuickBiteClients",
            ["Jwt:AccessTokenExpirationMinutes"] = "60",
            ["Jwt:RefreshTokenExpirationDays"] = "7",
            ["Resend:ApiKey"] = "",
            ["Supabase:ProjectUrl"] = "https://smoke.supabase.co",
            ["Supabase:ServiceRoleKey"] = "",
            ["Supabase:Bucket"] = "catalog-images"
        };

        return new ConfigurationBuilder()
            .AddInMemoryCollection(values)
            .Build();
    }

    [Fact]
    public void ContenedorDeDependencias_ResuelveTodosLosServiciosRegistrados()
    {
        var configuration = BuildConfiguration();
        var services = new ServiceCollection();

        services.AddSingleton<IConfiguration>(configuration);
        services.AddOptions();
        services.AddApplication();
        services.AddInfrastructure(configuration);

        using var provider = services.BuildServiceProvider(new ServiceProviderOptions
        {
            ValidateScopes = true,
            ValidateOnBuild = true
        });

        using var scope = provider.CreateScope();
        foreach (var descriptor in services)
        {
            if (descriptor.ServiceType.ContainsGenericParameters)
            {
                continue;
            }

            if (descriptor.IsKeyedService)
            {
                scope.ServiceProvider.GetRequiredKeyedService(descriptor.ServiceType, descriptor.ServiceKey);
            }
            else
            {
                scope.ServiceProvider.GetRequiredService(descriptor.ServiceType);
            }
        }
    }
}