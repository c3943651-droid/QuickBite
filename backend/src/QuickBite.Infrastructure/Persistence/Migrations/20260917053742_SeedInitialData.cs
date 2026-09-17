using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuickBite.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SeedInitialData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
INSERT INTO metodos_pago (id, nombre, descripcion, activo) VALUES
  ('d0000000-0000-0000-0000-000000000001', 'efectivo', 'Pago en efectivo contra entrega', TRUE),
  ('d0000000-0000-0000-0000-000000000002', 'tarjeta', 'Pago con tarjeta (simulado)', TRUE);

INSERT INTO configuracion_sistema (id, clave, valor, descripcion, editable, creado_en, actualizado_en) VALUES
  ('e0000000-0000-0000-0000-000000000001', 'costo_envio_default', '2.00', 'Costo de envío por defecto', TRUE, now(), now()),
  ('e0000000-0000-0000-0000-000000000002', 'tiempo_preparacion_estimado', '20', 'Minutos estimados de preparación', TRUE, now(), now()),
  ('e0000000-0000-0000-0000-000000000003', 'tiempo_entrega_estimado', '15', 'Minutos estimados de entrega', TRUE, now(), now()),
  ('e0000000-0000-0000-0000-000000000004', 'carrito_expiracion_horas', '24', 'Horas antes de expirar un carrito', TRUE, now(), now()),
  ('e0000000-0000-0000-0000-000000000005', 'max_intentos_login', '5', 'Intentos fallidos antes de bloqueo', TRUE, now(), now());

INSERT INTO usuarios
  (id, nombre, email, password_hash, telefono, rol, activo, intentos_fallidos, bloqueado_hasta, ultimo_login, creado_en, actualizado_en) VALUES
  ('a0000000-0000-0000-0000-000000000001', 'Administrador', 'admin@quickbite.com',
   '$2b$12$qv3pLXmiJreG6gU9hOBn0.k1mwH9LfqXJTcpYw1XJb1PoTIboVqtW', NULL, 'administrador', TRUE, 0, NULL, NULL, now(), now()),
  ('a0000000-0000-0000-0000-000000000002', 'Repartidor Demo', 'repartidor@quickbite.com',
   '$2b$12$qv3pLXmiJreG6gU9hOBn0.k1mwH9LfqXJTcpYw1XJb1PoTIboVqtW', NULL, 'repartidor', TRUE, 0, NULL, NULL, now(), now());

INSERT INTO repartidores (usuario_id, estado_disponibilidad, vehiculo, entregas_completadas, fecha_alta) VALUES
  ('a0000000-0000-0000-0000-000000000002', 'disponible', 'Moto', 0, now());

INSERT INTO categorias (id, nombre, descripcion, orden, activo, creado_en) VALUES
  ('b0000000-0000-0000-0000-000000000001', 'Hamburguesas', 'Hamburguesas clásicas y especiales', 1, TRUE, now()),
  ('b0000000-0000-0000-0000-000000000002', 'Bebidas', 'Refrescos, jugos y aguas', 2, TRUE, now()),
  ('b0000000-0000-0000-0000-000000000003', 'Postres', 'Postres y helados', 3, TRUE, now());

INSERT INTO productos
  (id, categoria_id, nombre, descripcion, precio, imagen_url, disponible, creado_en, actualizado_en) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000001', 'Hamburguesa Clásica', 'Pan, carne 150g, lechuga, tomate y cebolla', 45.00, 'https://placehold.co/400x300?text=Clasica', TRUE, now(), now()),
  ('c0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'Hamburguesa con Queso', 'Clásica con queso cheddar', 52.00, 'https://placehold.co/400x300?text=Queso', TRUE, now(), now()),
  ('c0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'Doble Carne', 'Doble carne 300g, queso y tocino', 70.00, 'https://placehold.co/400x300?text=Doble', TRUE, now(), now()),
  ('c0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000002', 'Refresco de Cola 500ml', 'Refresco de cola en presentación de 500ml', 18.00, 'https://placehold.co/400x300?text=Cola', TRUE, now(), now()),
  ('c0000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000002', 'Jugo Natural', 'Jugo natural de naranja recién exprimido', 25.00, 'https://placehold.co/400x300?text=Jugo', TRUE, now(), now()),
  ('c0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000003', 'Pastel de Chocolate', 'Porción de pastel de chocolate con ganache', 35.00, 'https://placehold.co/400x300?text=Pastel', TRUE, now(), now()),
  ('c0000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000003', 'Helado de Vainilla', 'Helado artesanal de vainilla', 22.00, 'https://placehold.co/400x300?text=Helado', TRUE, now(), now());

INSERT INTO inventario (producto_id, stock, stock_minimo, ultima_actualizacion, actualizado_por) VALUES
  ('c0000000-0000-0000-0000-000000000001', 50,  10, now(), NULL),
  ('c0000000-0000-0000-0000-000000000002', 50,  10, now(), NULL),
  ('c0000000-0000-0000-0000-000000000003', 30,  5,  now(), NULL),
  ('c0000000-0000-0000-0000-000000000004', 100, 20, now(), NULL),
  ('c0000000-0000-0000-0000-000000000005', 60,  15, now(), NULL),
  ('c0000000-0000-0000-0000-000000000006', 40,  10, now(), NULL),
  ('c0000000-0000-0000-0000-000000000007', 40,  10, now(), NULL);
");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
DELETE FROM repartidores WHERE usuario_id = 'a0000000-0000-0000-0000-000000000002';
DELETE FROM usuarios WHERE id IN ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002');

DELETE FROM inventario
WHERE producto_id BETWEEN 'c0000000-0000-0000-0000-000000000001' AND 'c0000000-0000-0000-0000-000000000007';

DELETE FROM productos
WHERE id BETWEEN 'c0000000-0000-0000-0000-000000000001' AND 'c0000000-0000-0000-0000-000000000007';

DELETE FROM categorias
WHERE id BETWEEN 'b0000000-0000-0000-0000-000000000001' AND 'b0000000-0000-0000-0000-000000000003';

DELETE FROM configuracion_sistema
WHERE id BETWEEN 'e0000000-0000-0000-0000-000000000001' AND 'e0000000-0000-0000-0000-000000000005';

DELETE FROM metodos_pago WHERE id IN ('d0000000-0000-0000-0000-000000000001', 'd0000000-0000-0000-0000-000000000002');
");
        }
    }
}