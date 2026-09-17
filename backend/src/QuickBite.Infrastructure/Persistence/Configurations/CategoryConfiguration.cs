using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> builder)
    {
        builder.ToTable("categorias");

        builder.Property(c => c.Nombre).HasMaxLength(100);
        builder.Property(c => c.Descripcion).HasMaxLength(255);

        builder.HasIndex(c => c.Nombre).IsUnique().HasDatabaseName("uq_categorias_nombre");
    }
}