using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBite.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// Corrección de datos: la liberación del repartidor vivía únicamente en un
    /// trigger de un script .sql que nunca se aplicaba, así que repartidores con
    /// pedidos ya entregados quedaron en 'ocupado'. Esta migración los devuelve a
    /// 'disponible' cuando no les queda ningún pedido pendiente.
    ///
    /// Es idempotente: sólo afecta a quien está ocupado y sin trabajo en curso.
    /// </summary>
    public partial class LiberarRepartidoresSinPedidosActivos : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                UPDATE repartidores r
                SET estado_disponibilidad = 'disponible'
                WHERE r.estado_disponibilidad = 'ocupado'
                  AND NOT EXISTS (
                    SELECT 1
                    FROM pedidos p
                    WHERE p.repartidor_id = r.usuario_id
                      AND p.estado NOT IN ('entregado', 'cancelado')
                  );
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No se revierte: no es posible saber qué repartidores estaban
            // realmente ocupados antes de la corrección.
        }
    }
}
