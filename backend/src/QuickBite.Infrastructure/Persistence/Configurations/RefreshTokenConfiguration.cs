using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class RefreshTokenConfiguration : IEntityTypeConfiguration<RefreshToken>
{
    public void Configure(EntityTypeBuilder<RefreshToken> builder)
    {
        builder.ToTable("tokens_refresco");

        builder.Property(t => t.TokenHash).HasMaxLength(255);
        builder.Property(t => t.IpOrigen).HasMaxLength(45);
        builder.Property(t => t.UserAgent).HasMaxLength(255);

        builder.HasIndex(t => t.UsuarioId).HasDatabaseName("idx_tokens_refresco_usuario_id");
        builder.HasIndex(t => t.ExpiraEn)
            .HasFilter("revocado = FALSE")
            .HasDatabaseName("idx_tokens_refresco_expiracion");

        builder.HasOne(t => t.Usuario)
            .WithMany(u => u.TokensRefresco)
            .HasForeignKey(t => t.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}