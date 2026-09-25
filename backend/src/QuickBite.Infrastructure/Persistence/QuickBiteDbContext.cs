using Microsoft.EntityFrameworkCore;
using Npgsql;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;

namespace QuickBite.Infrastructure.Persistence;

public class QuickBiteDbContext : DbContext
{
    static QuickBiteDbContext()
    {
#pragma warning disable CS0618
        NpgsqlConnection.GlobalTypeMapper.MapEnum<UserRole>("rol_usuario");
        NpgsqlConnection.GlobalTypeMapper.MapEnum<OrderStatus>("estado_pedido");
        NpgsqlConnection.GlobalTypeMapper.MapEnum<PaymentMethodType>("metodo_pago");
        NpgsqlConnection.GlobalTypeMapper.MapEnum<DeliveryPersonStatus>("estado_repartidor");
        NpgsqlConnection.GlobalTypeMapper.MapEnum<NotificationType>("tipo_notificacion");
#pragma warning restore CS0618
    }

    public QuickBiteDbContext(DbContextOptions<QuickBiteDbContext> options)
        : base(options)
    {
    }

    public DbSet<User> Usuarios => Set<User>();
    public DbSet<Address> Direcciones => Set<Address>();
    public DbSet<DeliveryPerson> Repartidores => Set<DeliveryPerson>();
    public DbSet<RefreshToken> TokensRefresco => Set<RefreshToken>();
    public DbSet<PasswordResetToken> TokensRecuperacionPassword => Set<PasswordResetToken>();
    public DbSet<Category> Categorias => Set<Category>();
    public DbSet<Product> Productos => Set<Product>();
    public DbSet<ProductPriceHistory> ProductosPreciosHistoricos => Set<ProductPriceHistory>();
    public DbSet<Inventory> Inventario => Set<Inventory>();
    public DbSet<PaymentMethod> MetodosPago => Set<PaymentMethod>();
    public DbSet<ProductOption> ProductosOpciones => Set<ProductOption>();
    public DbSet<Cart> Carritos => Set<Cart>();
    public DbSet<CartItem> CarritoItems => Set<CartItem>();
    public DbSet<CartItemOption> CarritoItemOpciones => Set<CartItemOption>();
    public DbSet<Order> Pedidos => Set<Order>();
    public DbSet<OrderItem> PedidoItems => Set<OrderItem>();
    public DbSet<OrderItemOption> PedidoItemOpciones => Set<OrderItemOption>();
    public DbSet<OrderStatusHistory> PedidoHistorialEstados => Set<OrderStatusHistory>();
    public DbSet<Notification> Notificaciones => Set<Notification>();
    public DbSet<AuditAction> AuditoriaAcciones => Set<AuditAction>();
    public DbSet<SystemConfig> ConfiguracionSistema => Set<SystemConfig>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.HasPostgresExtension("pgcrypto");

        modelBuilder.HasPostgresEnum<UserRole>(name: "rol_usuario");
        modelBuilder.HasPostgresEnum<OrderStatus>(name: "estado_pedido");
        modelBuilder.HasPostgresEnum<PaymentMethodType>(name: "metodo_pago");
        modelBuilder.HasPostgresEnum<DeliveryPersonStatus>(name: "estado_repartidor");
        modelBuilder.HasPostgresEnum<NotificationType>(name: "tipo_notificacion");

        modelBuilder.ApplyConfigurationsFromAssembly(typeof(QuickBiteDbContext).Assembly);
    }
}