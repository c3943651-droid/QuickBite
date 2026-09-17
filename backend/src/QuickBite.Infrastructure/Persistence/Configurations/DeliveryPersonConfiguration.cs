using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class DeliveryPersonConfiguration : IEntityTypeConfiguration<DeliveryPerson>
{
    public void Configure(EntityTypeBuilder<DeliveryPerson> builder)
    {
        builder.ToTable("repartidores");

        builder.HasKey(d => d.UsuarioId);

        builder.Property(d => d.Vehiculo).HasMaxLength(50);

        builder.HasIndex(d => d.EstadoDisponibilidad).HasDatabaseName("idx_repartidores_estado");
        builder.HasIndex(d => d.EntregasCompletadas)
            .IsDescending()
            .HasDatabaseName("idx_repartidores_entregas");

        builder.HasOne(d => d.Usuario)
            .WithOne(u => u.Repartidor)
            .HasForeignKey<DeliveryPerson>(d => d.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}