using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using QuickBite.Domain.Entities;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class OrderStatusHistoryConfiguration : IEntityTypeConfiguration<OrderStatusHistory>
{
    public void Configure(EntityTypeBuilder<OrderStatusHistory> builder)
    {
        builder.ToTable("pedido_historial_estados");

        builder.Property(h => h.Comentario).HasMaxLength(255);

        builder.HasOne(h => h.Pedido)
            .WithMany(o => o.HistorialEstados)
            .HasForeignKey(h => h.PedidoId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(h => h.Usuario)
            .WithMany()
            .HasForeignKey(h => h.UsuarioId);
    }
}