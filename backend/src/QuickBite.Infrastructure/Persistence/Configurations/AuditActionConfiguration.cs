using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class AuditActionConfiguration : IEntityTypeConfiguration<AuditAction>
{
    public void Configure(EntityTypeBuilder<AuditAction> builder)
    {
        builder.ToTable("auditoria_acciones");

        builder.Property(a => a.Accion).HasMaxLength(100);
        builder.Property(a => a.Entidad).HasMaxLength(50);
        builder.Property(a => a.Detalles).HasColumnType("jsonb");
        builder.Property(a => a.IpOrigen).HasMaxLength(45);
        builder.Property(a => a.UserAgent).HasColumnType("text");

        builder.HasIndex(a => a.UsuarioId).HasDatabaseName("idx_auditoria_usuario");
        builder.HasIndex(a => new { a.Entidad, a.EntidadId }).HasDatabaseName("idx_auditoria_entidad");
        builder.HasIndex(a => a.CreadoEn).IsDescending().HasDatabaseName("idx_auditoria_fecha");

        builder.HasOne(a => a.Usuario)
            .WithMany(u => u.Auditorias)
            .HasForeignKey(a => a.UsuarioId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}