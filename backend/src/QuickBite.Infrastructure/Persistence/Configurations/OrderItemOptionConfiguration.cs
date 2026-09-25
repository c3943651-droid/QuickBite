using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class OrderItemOptionConfiguration : IEntityTypeConfiguration<OrderItemOption>
{
    public void Configure(EntityTypeBuilder<OrderItemOption> builder)
    {
        builder.ToTable("pedido_item_opciones");

        builder.Property(o => o.NombreOpcion).HasMaxLength(100);
        builder.Property(o => o.PrecioAdicional).HasPrecision(10, 2);

        builder.HasOne(o => o.PedidoItem)
            .WithMany(i => i.Opciones)
            .HasForeignKey(o => o.PedidoItemId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}