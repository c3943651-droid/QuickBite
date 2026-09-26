-- QuickBite: limpieza de usuarios de prueba (seed demo) antes de usar datos reales.
-- Conserva: estructura de tablas, categorias, productos, inventario, metodos_pago y configuracion_sistema.
-- Idempotente: puede ejecutarse mas de una vez sin error.
-- Ejecutar con psql contra PostgreSQL (Supabase / Render) o en el SQL Editor de Supabase.
--   psql "$DATABASE_URL" -f backend/scripts/limpiar-usuarios-demo.sql

BEGIN;

-- Usuarios demo sembrados por migraciones (email @quickbite.com).
-- Se apunta tambien por id para cubrir variantes del email.
CREATE TEMP TABLE demo_users ON COMMIT DROP AS
SELECT id
FROM usuarios
WHERE email ILIKE '%@quickbite.com'
   OR id IN (
        'a0000000-0000-0000-0000-000000000001',
        'a0000000-0000-0000-0000-000000000002',
        'a0000000-0000-0000-0000-000000000003',
        'a0000000-0000-0000-0000-000000000004'
   );

-- Pedidos de usuarios demo primero: pedidos.cliente_id es Restrict,
-- por lo que impide borrar el usuario mientras existan pedidos.
DELETE FROM pedidos
WHERE cliente_id IN (SELECT id FROM demo_users)
   OR repartidor_id IN (SELECT id FROM demo_users);

-- Demas tablas dependientes (direcciones, carritos, carrito_items, carrito_item_opciones,
-- repartidores, notificaciones, tokens_refresco, tokens_recuperacion_password) se borran
-- en cascada. auditoria_acciones, inventario.actualizado_por, producto_precios_historicos
-- y pedido_historial_estados quedan con usuario nulo (SetNull).
DELETE FROM usuarios
WHERE id IN (SELECT id FROM demo_users);

-- Registros de auditoria sembrados en SeedDemoData (referencias a usuarios demo).
DELETE FROM auditoria_acciones
WHERE id IN (
    'f0000000-0000-0000-0000-000000000001',
    'f0000000-0000-0000-0000-000000000002',
    'f0000000-0000-0000-0000-000000000003'
);

COMMIT;

DO $$
DECLARE restantes integer;
BEGIN
    SELECT count(*) INTO restantes FROM usuarios WHERE email ILIKE '%@quickbite.com';
    IF restantes > 0 THEN
        RAISE NOTICE 'ATENCION: quedan % usuarios demo sin limpiar', restantes;
    END IF;
END $$;