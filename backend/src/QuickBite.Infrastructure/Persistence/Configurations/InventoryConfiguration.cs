using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class InventoryConfiguration : IEntityTypeConfiguration<Inventory>
{
    public void Configure(EntityTypeBuilder<Inventory> builder)
    {
        builder.ToTable(
            "inventario",
            table => table.HasCheckConstraint("CK_inventario_stock", "stock >= 0"));

        builder.HasKey(i => i.ProductoId);

        builder.HasIndex(i => i.ProductoId)
            .HasFilter("stock <= stock_minimo")
            .HasDatabaseName("idx_inventario_stock_bajo");

        builder.HasOne(i => i.Producto)
            .WithOne(p => p.Inventario)
            .HasForeignKey<Inventory>(i => i.ProductoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(i => i.ActualizadoPorUsuario)
            .WithMany()
            .HasForeignKey(i => i.ActualizadoPor)
            .OnDelete(DeleteBehavior.SetNull);
    }
}