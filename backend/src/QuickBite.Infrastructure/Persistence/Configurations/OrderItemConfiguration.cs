using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class OrderItemConfiguration : IEntityTypeConfiguration<OrderItem>
{
    public void Configure(EntityTypeBuilder<OrderItem> builder)
    {
        builder.ToTable(
            "pedido_items",
            table =>
            {
                table.HasCheckConstraint("CK_pedido_items_precio", "precio_unitario >= 0");
                table.HasCheckConstraint("CK_pedido_items_cantidad", "cantidad > 0");
                table.HasCheckConstraint("CK_pedido_items_subtotal", "subtotal >= 0");
            });

        builder.Property(i => i.NombreProducto).HasMaxLength(150);
        builder.Property(i => i.PrecioUnitario).HasPrecision(10, 2);
        builder.Property(i => i.Observaciones).HasMaxLength(255);
        builder.Property(i => i.Subtotal).HasPrecision(10, 2);

        builder.HasIndex(i => new { i.PedidoId, i.ProductoId })
            .IsUnique()
            .HasFilter("producto_id IS NOT NULL")
            .HasDatabaseName("uq_pedido_items_producto");
        builder.HasIndex(i => i.PedidoId).HasDatabaseName("idx_pedido_items_pedido_id");
        builder.HasIndex(i => i.ProductoId).HasDatabaseName("idx_pedido_items_producto");

        builder.HasOne(i => i.Pedido)
            .WithMany(o => o.Items)
            .HasForeignKey(i => i.PedidoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(i => i.Producto)
            .WithMany()
            .HasForeignKey(i => i.ProductoId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}