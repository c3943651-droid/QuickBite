using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBite.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddTriggerValidarAsignacionRepartidor : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                CREATE OR REPLACE FUNCTION validar_asignacion_repartidor()
                RETURNS TRIGGER AS $$
                BEGIN
                  IF NEW.repartidor_id IS DISTINCT FROM OLD.repartidor_id THEN
                    IF NEW.estado <> 'listo' THEN
                      RAISE EXCEPTION 'Solo se pueden asignar repartidores a pedidos en estado ''listo'' (estado actual: %)', NEW.estado;
                    END IF;
                  END IF;
                  RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER trg_validar_asignacion_repartidor
                  BEFORE UPDATE ON pedidos
                  FOR EACH ROW EXECUTE FUNCTION validar_asignacion_repartidor();
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DROP TRIGGER IF EXISTS trg_validar_asignacion_repartidor ON pedidos;
                DROP FUNCTION IF EXISTS validar_asignacion_repartidor();
                """);
        }
    }
}