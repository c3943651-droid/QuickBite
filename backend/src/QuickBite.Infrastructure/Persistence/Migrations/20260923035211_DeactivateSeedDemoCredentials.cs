using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBite.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class DeactivateSeedDemoCredentials : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                UPDATE usuarios
                SET activo = FALSE, actualizado_en = now()
                WHERE email IN ('admin@quickbite.com', 'repartidor@quickbite.com')
                  AND activo = TRUE;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                UPDATE usuarios
                SET activo = TRUE, actualizado_en = now()
                WHERE email IN ('admin@quickbite.com', 'repartidor@quickbite.com');
                """);
        }
    }
}
