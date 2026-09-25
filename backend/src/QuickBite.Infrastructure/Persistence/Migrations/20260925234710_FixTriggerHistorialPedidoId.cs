using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBite.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class FixTriggerHistorialPedidoId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DROP TRIGGER IF EXISTS trg_registrar_historial_pedido ON pedidos;
                DROP FUNCTION IF EXISTS registrar_historial_pedido();

                CREATE OR REPLACE FUNCTION registrar_historial_pedido()
                RETURNS TRIGGER AS $$
                BEGIN
                  IF TG_OP = 'INSERT' THEN
                    INSERT INTO pedido_historial_estados (id, pedido_id, estado_anterior, estado_nuevo, usuario_id, creado_en)
                    VALUES (gen_random_uuid(), NEW.id, NULL, NEW.estado, NEW.cliente_id, now());
                  END IF;
                  RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER trg_registrar_historial_pedido
                  AFTER INSERT ON pedidos
                  FOR EACH ROW EXECUTE FUNCTION registrar_historial_pedido();
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DROP TRIGGER IF EXISTS trg_registrar_historial_pedido ON pedidos;
                DROP FUNCTION IF EXISTS registrar_historial_pedido();

                CREATE OR REPLACE FUNCTION registrar_historial_pedido()
                RETURNS TRIGGER AS $$
                BEGIN
                  IF TG_OP = 'INSERT' THEN
                    INSERT INTO pedido_historial_estados (id, pedido_id, estado_anterior, estado_nuevo, usuario_id, creado_en)
                    VALUES (gen_random_uuid(), NEW.id, NULL, NEW.estado, NEW.cliente_id, now());
                  END IF;
                  RETURN NEW;
                END;
                $$ LANGUAGE plpgsql;

                CREATE TRIGGER trg_registrar_historial_pedido
                  AFTER INSERT ON pedidos
                  FOR EACH ROW EXECUTE FUNCTION registrar_historial_pedido();
                """);
        }
    }
}