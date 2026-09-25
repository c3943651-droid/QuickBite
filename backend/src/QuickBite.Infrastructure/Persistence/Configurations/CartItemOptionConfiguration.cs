using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class CartItemOptionConfiguration : IEntityTypeConfiguration<CartItemOption>
{
    public void Configure(EntityTypeBuilder<CartItemOption> builder)
    {
        builder.ToTable("carrito_item_opciones");

        builder.HasOne(o => o.CarritoItem)
            .WithMany(i => i.Opciones)
            .HasForeignKey(o => o.CarritoItemId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(o => o.Opcion)
            .WithMany()
            .HasForeignKey(o => o.OpcionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}