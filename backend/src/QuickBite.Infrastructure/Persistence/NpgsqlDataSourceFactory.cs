using Npgsql;
using QuickBite.Domain.Enums;

namespace QuickBite.Infrastructure.Persistence;

public static class NpgsqlDataSourceFactory
{
    private const int DefaultMaxPoolSize = 6;
    private const int DefaultConnectionIdleLifetimeSeconds = 60;

    public static NpgsqlDataSource Create(string? connectionString)
    {
        var csb = new NpgsqlConnectionStringBuilder(connectionString);
        if (!HasKeyword(csb, "Maximum Pool Size"))
        {
            csb.MaxPoolSize = DefaultMaxPoolSize;
        }

        if (!HasKeyword(csb, "Connection Idle Lifetime"))
        {
            csb.ConnectionIdleLifetime = DefaultConnectionIdleLifetimeSeconds;
        }

        var builder = new NpgsqlDataSourceBuilder(csb.ConnectionString);
        builder.MapEnum<UserRole>("rol_usuario");
        builder.MapEnum<OrderStatus>("estado_pedido");
        builder.MapEnum<PaymentMethodType>("metodo_pago");
        builder.MapEnum<DeliveryPersonStatus>("estado_repartidor");
        builder.MapEnum<NotificationType>("tipo_notificacion");
        builder.EnableDynamicJson();
        return builder.Build();
    }

    private static bool HasKeyword(NpgsqlConnectionStringBuilder csb, string keyword)
        => csb.Keys.Cast<string>().Any(k => string.Equals(k, keyword, StringComparison.OrdinalIgnoreCase));
}