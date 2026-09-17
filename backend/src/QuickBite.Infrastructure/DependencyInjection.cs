using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Npgsql;
using Npgsql.EntityFrameworkCore.PostgreSQL;
using QuickBite.Domain.Enums;
using QuickBite.Domain.Repositories;
using QuickBite.Infrastructure.Persistence;
using QuickBite.Infrastructure.Persistence.Repositories;

namespace QuickBite.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        services.AddSingleton(sp =>
        {
            var connectionString = sp.GetRequiredService<IConfiguration>()
                .GetConnectionString("DefaultConnection");
            var builder = new NpgsqlDataSourceBuilder(connectionString);
            builder.MapEnum<UserRole>("rol_usuario");
            builder.MapEnum<OrderStatus>("estado_pedido");
            builder.MapEnum<PaymentMethodType>("metodo_pago");
            builder.MapEnum<DeliveryPersonStatus>("estado_repartidor");
            builder.MapEnum<NotificationType>("tipo_notificacion");
            builder.EnableDynamicJson();
            return builder.Build();
        });

        services.AddDbContext<QuickBiteDbContext>((sp, options) =>
            options.UseNpgsql(
                    sp.GetRequiredService<NpgsqlDataSource>(),
                    npgsql => npgsql.EnableRetryOnFailure())
                .UseSnakeCaseNamingConvention());

        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<IAddressRepository, AddressRepository>();
        services.AddScoped<IDeliveryPersonRepository, DeliveryPersonRepository>();
        services.AddScoped<IProductRepository, ProductRepository>();
        services.AddScoped<ICategoryRepository, CategoryRepository>();
        services.AddScoped<ICartRepository, CartRepository>();
        services.AddScoped<IOrderRepository, OrderRepository>();
        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<IAuditRepository, AuditRepository>();
        services.AddScoped<IConfigRepository, ConfigRepository>();

        return services;
    }
}