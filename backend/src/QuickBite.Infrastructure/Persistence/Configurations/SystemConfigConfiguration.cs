using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class SystemConfigConfiguration : IEntityTypeConfiguration<SystemConfig>
{
    public void Configure(EntityTypeBuilder<SystemConfig> builder)
    {
        builder.ToTable("configuracion_sistema");

        builder.Property(c => c.Clave).HasMaxLength(50);
        builder.Property(c => c.Valor).HasColumnType("text");
        builder.Property(c => c.Descripcion).HasMaxLength(255);

        builder.HasIndex(c => c.Clave).IsUnique().HasDatabaseName("uq_configuracion_sistema_clave");
    }
}