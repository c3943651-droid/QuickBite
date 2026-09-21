using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBite.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SeedDemoData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
INSERT INTO usuarios
  (id, nombre, email, password_hash, telefono, rol, activo, intentos_fallidos, bloqueado_hasta, ultimo_login, creado_en, actualizado_en) VALUES
  ('a0000000-0000-0000-0000-000000000003', 'Repartidor Uno', 'repartidor1@quickbite.com',
   '$2b$12$qv3pLXmiJreG6gU9hOBn0.k1mwH9LfqXJTcpYw1XJb1PoTIboVqtW', NULL, 'repartidor', TRUE, 0, NULL, NULL, now(), now()),
  ('a0000000-0000-0000-0000-000000000004', 'Repartidor Dos', 'repartidor2@quickbite.com',
   '$2b$12$qv3pLXmiJreG6gU9hOBn0.k1mwH9LfqXJTcpYw1XJb1PoTIboVqtW', NULL, 'repartidor', TRUE, 0, NULL, NULL, now(), now());

INSERT INTO auditoria_acciones
  (id, usuario_id, accion, entidad, entidad_id, detalles, ip_origen, user_agent, creado_en) VALUES
  ('f0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 'seed_inicial', 'sistema', NULL,
   '{""origen"":""seed""}'::jsonb, NULL, NULL, now()),
  ('f0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'login', 'sesion', 'a0000000-0000-0000-0000-000000000001',
   '{""origen"":""seed""}'::jsonb, '127.0.0.1', NULL, now()),
  ('f0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002', 'alta', 'repartidor', 'a0000000-0000-0000-0000-000000000002',
   '{""origen"":""seed""}'::jsonb, NULL, NULL, now());
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
DELETE FROM auditoria_acciones
WHERE id BETWEEN 'f0000000-0000-0000-0000-000000000001' AND 'f0000000-0000-0000-0000-000000000003';

DELETE FROM usuarios WHERE id IN ('a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000004');
");
        }
    }
}