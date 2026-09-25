using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable(
            "usuarios",
            table => table.HasCheckConstraint("CK_usuarios_email", "email ~* '^[^@]+@[^@]+\\.[^@]+$'"));

        builder.Property(u => u.Nombre).HasMaxLength(150);
        builder.Property(u => u.Email).HasMaxLength(255);
        builder.Property(u => u.PasswordHash).HasMaxLength(255);
        builder.Property(u => u.Telefono).HasMaxLength(20);

        builder.HasIndex(u => u.Email).IsUnique().HasDatabaseName("uq_usuarios_email");
        builder.HasIndex(u => u.Rol).HasDatabaseName("idx_usuarios_rol");
        builder.HasIndex(u => u.Activo).HasFilter("activo = TRUE").HasDatabaseName("idx_usuarios_activo");
    }
}