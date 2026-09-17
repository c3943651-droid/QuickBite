using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class PaymentMethodConfiguration : IEntityTypeConfiguration<PaymentMethod>
{
    public void Configure(EntityTypeBuilder<PaymentMethod> builder)
    {
        builder.ToTable("metodos_pago");

        builder.Property(p => p.Nombre).HasMaxLength(50);
        builder.Property(p => p.Descripcion).HasMaxLength(200);

        builder.HasIndex(p => p.Nombre).IsUnique().HasDatabaseName("uq_metodos_pago_nombre");
    }
}