using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class ProductConfiguration : IEntityTypeConfiguration<Product>
{
    public void Configure(EntityTypeBuilder<Product> builder)
    {
        builder.ToTable(
            "productos",
            table => table.HasCheckConstraint("CK_productos_precio", "precio >= 0"));

        builder.Property(p => p.Nombre).HasMaxLength(150);
        builder.Property(p => p.Descripcion).HasColumnType("text");
        builder.Property(p => p.Precio).HasPrecision(10, 2);
        builder.Property(p => p.ImagenUrl).HasMaxLength(500);

        builder.HasIndex(p => p.CategoriaId).HasDatabaseName("idx_productos_categoria_id");
        builder.HasIndex(p => p.Disponible).HasFilter("disponible = TRUE").HasDatabaseName("idx_productos_disponible");
        builder.HasIndex(p => p.Precio).HasDatabaseName("idx_productos_precio");

        builder.HasOne(p => p.Categoria)
            .WithMany(c => c.Productos)
            .HasForeignKey(p => p.CategoriaId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}