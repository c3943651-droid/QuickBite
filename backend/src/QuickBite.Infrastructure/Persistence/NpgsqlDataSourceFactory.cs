using Npgsql;
using QuickBite.Domain.Enums;

namespace QuickBite.Infrastructure.Persistence;

public static class NpgsqlDataSourceFactory
{
    public static NpgsqlDataSource Create(string? connectionString)
    {
        var builder = new NpgsqlDataSourceBuilder(connectionString);
        builder.MapEnum<UserRole>("rol_usuario");
        builder.MapEnum<OrderStatus>("estado_pedido");
        builder.MapEnum<PaymentMethodType>("metodo_pago");
        builder.MapEnum<DeliveryPersonStatus>("estado_repartidor");
        builder.MapEnum<NotificationType>("tipo_notificacion");
        builder.EnableDynamicJson();
        return builder.Build();
    }
}