using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using QuickBite.Domain.Entities;
using QuickBite.Domain.Enums;

namespace QuickBite.Infrastructure.Persistence.Configurations;

public class CartConfiguration : IEntityTypeConfiguration<Cart>
{
    public void Configure(EntityTypeBuilder<Cart> builder)
    {
        builder.ToTable(
            "carritos",
            table => table.HasCheckConstraint(
                "CK_carritos_estado",
                "estado IN ('activo','abandonado','convertido')"));

        builder.Property(c => c.Estado)
            .HasConversion(CartStatusConverter)
            .HasMaxLength(20)
            .HasDefaultValue(CartStatus.Activo);

        builder.HasIndex(c => c.UsuarioId).IsUnique().HasDatabaseName("uq_carritos_usuario_id");
        builder.HasIndex(c => c.ExpiraEn)
            .HasFilter("estado = 'activo'")
            .HasDatabaseName("idx_carritos_expiracion");
        builder.HasIndex(c => c.Estado).HasDatabaseName("idx_carritos_estado");

        builder.HasOne(c => c.Usuario)
            .WithOne(u => u.Carrito)
            .HasForeignKey<Cart>(c => c.UsuarioId)
            .OnDelete(DeleteBehavior.Cascade);
    }

    private static readonly ValueConverter<CartStatus, string> CartStatusConverter = new(
        v => MapCartStatusToDatabase(v),
        v => MapCartStatusFromDatabase(v));

    private static string MapCartStatusToDatabase(CartStatus status) =>
        status switch
        {
            CartStatus.Activo => "activo",
            CartStatus.Abandonado => "abandonado",
            CartStatus.Convertido => "convertido",
            _ => throw new ArgumentOutOfRangeException(nameof(status), status, "Estado de carrito desconocido")
        };

    private static CartStatus MapCartStatusFromDatabase(string value) =>
        value switch
        {
            "activo" => CartStatus.Activo,
            "abandonado" => CartStatus.Abandonado,
            "convertido" => CartStatus.Convertido,
            _ => throw new ArgumentOutOfRangeException(nameof(value), value, "Estado de carrito desconocido")
        };
}