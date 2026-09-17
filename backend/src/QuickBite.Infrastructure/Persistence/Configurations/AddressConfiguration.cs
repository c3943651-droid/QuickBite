using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class AddressConfiguration : IEntityTypeConfiguration<Address>
{
    public void Configure(EntityTypeBuilder<Address> builder)
    {
        builder.ToTable("direcciones");

        builder.Property(a => a.Alias).HasMaxLength(50);
        builder.Property(a => a.Calle).HasMaxLength(200);
        builder.Property(a => a.Numero).HasMaxLength(20);
        builder.Property(a => a.Referencia).HasMaxLength(255);
        builder.Property(a => a.Ciudad).HasMaxLength(100);
        builder.Property(a => a.Latitud).HasPrecision(10, 7);
        builder.Property(a => a.Longitud).HasPrecision(10, 7);

        builder.HasIndex(a => a.UsuarioId).HasDatabaseName("idx_direcciones_usuario_id");
        builder.HasIndex(a => a.Ciudad).HasDatabaseName("idx_direcciones_ciudad");
        builder.HasIndex(a => new { a.UsuarioId })
            .IsUnique()
            .HasFilter("es_predeterminada = TRUE")
            .HasDatabaseName("uq_direccion_predeterminada_por_usuario");

        builder.HasOne(a => a.Usuario)
            .WithMany(u => u.Direcciones)
            .HasForeignKey(a => a.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}