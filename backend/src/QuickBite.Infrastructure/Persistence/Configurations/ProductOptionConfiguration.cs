using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class ProductOptionConfiguration : IEntityTypeConfiguration<ProductOption>
{
    public void Configure(EntityTypeBuilder<ProductOption> builder)
    {
        builder.ToTable(
            "producto_opciones",
            table => table.HasCheckConstraint("CK_producto_opciones_precio", "precio_adicional >= 0"));

        builder.Property(o => o.Nombre).HasMaxLength(100);
        builder.Property(o => o.PrecioAdicional).HasPrecision(10, 2);

        builder.HasOne(o => o.Producto)
            .WithMany(p => p.Opciones)
            .HasForeignKey(o => o.ProductoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}