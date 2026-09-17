using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class PasswordResetTokenConfiguration : IEntityTypeConfiguration<PasswordResetToken>
{
    public void Configure(EntityTypeBuilder<PasswordResetToken> builder)
    {
        builder.ToTable("tokens_recuperacion_password");

        builder.Property(t => t.TokenHash).HasMaxLength(255);

        builder.HasOne(t => t.Usuario)
            .WithMany(u => u.TokensRecuperacion)
            .HasForeignKey(t => t.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}