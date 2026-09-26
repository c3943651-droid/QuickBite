using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBite.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SeedConfiguracionSistemaOperativa : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO configuracion_sistema (id, clave, valor, descripcion, editable, creado_en, actualizado_en)
                SELECT gen_random_uuid(), v.clave, v.valor, v.descripcion, TRUE, now(), now()
                FROM (VALUES
                  ('restaurante_abierto', 'true', 'Indica si el restaurante está abierto para recibir pedidos'),
                  ('horario_apertura', '08:00', 'Hora de apertura en formato HH:MM'),
                  ('horario_cierre', '22:00', 'Hora de cierre en formato HH:MM'),
                  ('moneda_simbolo', '$', 'Símbolo de la moneda para mostrar precios'),
                  ('moneda_codigo', 'USD', 'Código ISO 4217 de la moneda')
                ) AS v(clave, valor, descripcion)
                WHERE NOT EXISTS (SELECT 1 FROM configuracion_sistema c WHERE c.clave = v.clave);
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM configuracion_sistema
                WHERE clave IN ('restaurante_abierto', 'horario_apertura', 'horario_cierre', 'moneda_simbolo', 'moneda_codigo');
                """);
        }
    }
}
