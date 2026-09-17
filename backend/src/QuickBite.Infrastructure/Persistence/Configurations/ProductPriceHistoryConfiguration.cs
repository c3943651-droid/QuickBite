using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class ProductPriceHistoryConfiguration : IEntityTypeConfiguration<ProductPriceHistory>
{
    public void Configure(EntityTypeBuilder<ProductPriceHistory> builder)
    {
        builder.ToTable("producto_precios_historicos");

        builder.Property(p => p.PrecioAnterior).HasPrecision(10, 2);
        builder.Property(p => p.PrecioNuevo).HasPrecision(10, 2);
        builder.Property(p => p.Motivo).HasMaxLength(255);

        builder.HasOne(p => p.Producto)
            .WithMany(p => p.PreciosHistoricos)
            .HasForeignKey(p => p.ProductoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(p => p.Usuario)
            .WithMany()
            .HasForeignKey(p => p.UsuarioId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}