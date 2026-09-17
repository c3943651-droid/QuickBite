using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class OrderConfiguration : IEntityTypeConfiguration<Order>
{
    public void Configure(EntityTypeBuilder<Order> builder)
    {
        builder.ToTable(
            "pedidos",
            table =>
            {
                table.HasCheckConstraint("CK_pedidos_subtotal", "subtotal >= 0");
                table.HasCheckConstraint("CK_pedidos_costo_envio", "costo_envio >= 0");
                table.HasCheckConstraint("CK_pedidos_total", "total >= 0");
            });

        builder.Property(o => o.NumeroPedido).HasMaxLength(20);
        builder.Property(o => o.DireccionEntregaSnapshot).HasColumnType("text");
        builder.Property(o => o.MotivoCancelacion).HasMaxLength(255);
        builder.Property(o => o.Subtotal).HasPrecision(10, 2);
        builder.Property(o => o.CostoEnvio).HasPrecision(10, 2);
        builder.Property(o => o.Total).HasPrecision(10, 2);

        builder.HasIndex(o => o.NumeroPedido).IsUnique().HasDatabaseName("uq_pedidos_numero");
        builder.HasIndex(o => o.ClienteId).HasDatabaseName("idx_pedidos_cliente");
        builder.HasIndex(o => o.RepartidorId).HasDatabaseName("idx_pedidos_repartidor");
        builder.HasIndex(o => o.Estado).HasDatabaseName("idx_pedidos_estado");
        builder.HasIndex(o => o.CreadoEn).IsDescending().HasDatabaseName("idx_pedidos_creado");
        builder.HasIndex(o => new { o.Estado, o.CreadoEn })
            .IsDescending(new[] { false, true })
            .HasDatabaseName("idx_pedidos_estado_fecha");

        builder.HasOne(o => o.Cliente)
            .WithMany(u => u.Pedidos)
            .HasForeignKey(o => o.ClienteId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.Repartidor)
            .WithMany(d => d.Pedidos)
            .HasForeignKey(o => o.RepartidorId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(o => o.Direccion)
            .WithMany()
            .HasForeignKey(o => o.DireccionId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(o => o.MetodoPagoCatalogo)
            .WithMany()
            .HasForeignKey(o => o.MetodoPagoId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}