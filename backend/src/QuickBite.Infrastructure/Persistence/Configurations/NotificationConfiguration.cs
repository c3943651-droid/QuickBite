using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> builder)
    {
        builder.ToTable("notificaciones");

        builder.Property(n => n.Titulo).HasMaxLength(150);
        builder.Property(n => n.Mensaje).HasMaxLength(500);

        builder.HasOne(n => n.Usuario)
            .WithMany(u => u.Notificaciones)
            .HasForeignKey(n => n.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(n => n.Pedido)
            .WithMany(o => o.Notificaciones)
            .HasForeignKey(n => n.PedidoId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}