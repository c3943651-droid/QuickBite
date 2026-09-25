-- =====================================================================
-- QuickBite v1.0 — Funciones, triggers y vistas (no gestionados por EF Core)
-- Ver docs/05 — D-05 y D-10: la migración EF Core es la línea base del
-- esquema; este script aporta lógica crítica y objetos de reporte.
-- Idempotente: puede ejecutarse más de una vez.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------
-- Índice GIN trigramático del catálogo (fuera del modelo EF Core)
-- ---------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'idx_productos_nombre_trgm'
  ) THEN
    CREATE INDEX idx_productos_nombre_trgm
      ON productos USING GIN (lower(nombre) gin_trgm_ops);
  END IF;
END $$;

-- ---------------------------------------------------------------------
-- Función genérica de timestamp
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_actualizado_en()
RETURNS TRIGGER AS $$
BEGIN
  NEW.actualizado_en = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_usuarios_actualizado_en BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

CREATE TRIGGER trg_productos_actualizado_en BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

CREATE TRIGGER trg_config_actualizado_en BEFORE UPDATE ON configuracion_sistema
  FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

-- ---------------------------------------------------------------------
-- Repartidores
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validar_rol_repartidor()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM usuarios WHERE id = NEW.usuario_id AND rol = 'repartidor'
  ) THEN
    RAISE EXCEPTION 'El usuario % no tiene rol repartidor', NEW.usuario_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_rol_repartidor BEFORE INSERT ON repartidores
  FOR EACH ROW EXECUTE FUNCTION validar_rol_repartidor();

CREATE OR REPLACE FUNCTION validar_transicion_repartidor()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.estado_disponibilidad = 'disponible' THEN
    IF EXISTS (
      SELECT 1 FROM pedidos
      WHERE repartidor_id = NEW.usuario_id
        AND estado IN ('en_camino')
    ) THEN
      RAISE EXCEPTION 'Repartidor % tiene pedidos activos', NEW.usuario_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_transicion_repartidor BEFORE UPDATE ON repartidores
  FOR EACH ROW EXECUTE FUNCTION validar_transicion_repartidor();

-- ---------------------------------------------------------------------
-- Carrito
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION actualizar_carrito_acceso()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE carritos
  SET ultimo_acceso = now(),
      expira_en = now() + INTERVAL '24 hours',
      actualizado_en = now()
  WHERE id = NEW.carrito_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_actualizar_carrito_acceso
  AFTER INSERT OR UPDATE ON carrito_items
  FOR EACH ROW EXECUTE FUNCTION actualizar_carrito_acceso();

-- ---------------------------------------------------------------------
-- Pedidos
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validar_transicion_pedido()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.estado = NEW.estado THEN
    RETURN NEW;
  END IF;

  IF NOT (
    (OLD.estado = 'pendiente'  AND NEW.estado IN ('confirmado','cancelado')) OR
    (OLD.estado = 'confirmado' AND NEW.estado IN ('preparando','cancelado')) OR
    (OLD.estado = 'preparando' AND NEW.estado IN ('listo','cancelado')) OR
    (OLD.estado = 'listo'      AND NEW.estado IN ('en_camino','cancelado')) OR
    (OLD.estado = 'en_camino'  AND NEW.estado = 'entregado')
  ) THEN
    RAISE EXCEPTION 'Transición de estado no permitida: % -> %', OLD.estado, NEW.estado;
  END IF;

  IF NEW.estado = 'confirmado' THEN NEW.confirmado_en = now(); END IF;
  IF NEW.estado = 'preparando' THEN NEW.preparando_en = now(); END IF;
  IF NEW.estado = 'listo'      THEN NEW.listo_en = now(); END IF;
  IF NEW.estado = 'en_camino'  THEN NEW.en_camino_en = now(); END IF;
  IF NEW.estado = 'entregado'  THEN NEW.entregado_en = now(); END IF;
  IF NEW.estado = 'cancelado'  THEN NEW.cancelado_en = now(); END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_transicion_pedido BEFORE UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION validar_transicion_pedido();

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

CREATE TRIGGER trg_validar_asignacion_repartidor BEFORE UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION validar_asignacion_repartidor();

CREATE OR REPLACE FUNCTION registrar_historial_pedido()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO pedido_historial_estados (pedido_id, estado_anterior, estado_nuevo, usuario_id)
    VALUES (NEW.id, NULL, NEW.estado, NEW.cliente_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_historial_pedido
  AFTER INSERT ON pedidos
  FOR EACH ROW EXECUTE FUNCTION registrar_historial_pedido();

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relkind = 'S' AND relname = 'seq_numero_pedido') THEN
    CREATE SEQUENCE seq_numero_pedido;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION generar_numero_pedido()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.numero_pedido IS NULL OR NEW.numero_pedido = '' THEN
    NEW.numero_pedido := 'QB-' || to_char(now(), 'YYYYMMDD') || '-' ||
      LPAD(nextval('seq_numero_pedido')::TEXT, 5, '0');
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_generar_numero_pedido BEFORE INSERT ON pedidos
  FOR EACH ROW EXECUTE FUNCTION generar_numero_pedido();

CREATE OR REPLACE FUNCTION validar_stock_pedido()
RETURNS TRIGGER AS $$
DECLARE
  item RECORD;
  stock_actual INTEGER;
BEGIN
  IF OLD.estado = 'pendiente' AND NEW.estado IN ('confirmado','preparando') THEN
    FOR item IN SELECT producto_id, cantidad FROM pedido_items WHERE pedido_id = NEW.id LOOP
      SELECT stock INTO stock_actual FROM inventario WHERE producto_id = item.producto_id;
      IF stock_actual IS NULL OR stock_actual < item.cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente para producto %', item.producto_id;
      END IF;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_stock_pedido BEFORE UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION validar_stock_pedido();

CREATE OR REPLACE FUNCTION descontar_stock_pedido()
RETURNS TRIGGER AS $$
DECLARE
  item RECORD;
BEGIN
  IF OLD.estado = 'pendiente' AND NEW.estado IN ('confirmado','preparando') THEN
    FOR item IN SELECT producto_id, cantidad FROM pedido_items WHERE pedido_id = NEW.id LOOP
      UPDATE inventario
      SET stock = stock - item.cantidad,
          ultima_actualizacion = now()
      WHERE producto_id = item.producto_id;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_descontar_stock_pedido AFTER UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION descontar_stock_pedido();

CREATE OR REPLACE FUNCTION restaurar_stock_pedido()
RETURNS TRIGGER AS $$
DECLARE
  item RECORD;
BEGIN
  IF OLD.estado IN ('confirmado','preparando','listo','en_camino') AND NEW.estado = 'cancelado' THEN
    FOR item IN SELECT producto_id, cantidad FROM pedido_items WHERE pedido_id = NEW.id LOOP
      UPDATE inventario
      SET stock = stock + item.cantidad,
          ultima_actualizacion = now()
      WHERE producto_id = item.producto_id;
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_restaurar_stock_pedido AFTER UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION restaurar_stock_pedido();

CREATE OR REPLACE FUNCTION incrementar_entregas_repartidor()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.estado = 'en_camino' AND NEW.estado = 'entregado' AND NEW.repartidor_id IS NOT NULL THEN
    UPDATE repartidores
    SET entregas_completadas = entregas_completadas + 1,
        estado_disponibilidad = 'disponible'
    WHERE usuario_id = NEW.repartidor_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_incrementar_entregas_repartidor AFTER UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION incrementar_entregas_repartidor();

-- ---------------------------------------------------------------------
-- Vistas de reporte
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW vista_pedidos_por_dia AS
SELECT
  date_trunc('day', creado_en)::date AS dia,
  COUNT(*) AS total_pedidos,
  COUNT(*) FILTER (WHERE estado = 'entregado') AS entregados,
  COUNT(*) FILTER (WHERE estado = 'cancelado') AS cancelados,
  COUNT(*) FILTER (WHERE estado NOT IN ('entregado','cancelado')) AS activos,
  COALESCE(SUM(total) FILTER (WHERE estado = 'entregado'), 0) AS ingresos,
  COALESCE(AVG(total) FILTER (WHERE estado = 'entregado'), 0) AS ticket_promedio
FROM pedidos
GROUP BY dia
ORDER BY dia DESC;

CREATE OR REPLACE VIEW vista_productos_mas_vendidos AS
SELECT
  pi.producto_id,
  pi.nombre_producto,
  SUM(pi.cantidad) AS unidades_vendidas,
  SUM(pi.subtotal) AS ingresos_generados,
  COUNT(DISTINCT pi.pedido_id) AS numero_pedidos
FROM pedido_items pi
JOIN pedidos p ON p.id = pi.pedido_id
WHERE p.estado = 'entregado'
GROUP BY pi.producto_id, pi.nombre_producto
ORDER BY unidades_vendidas DESC;

CREATE OR REPLACE VIEW vista_clientes_frecuentes AS
SELECT
  u.id AS cliente_id,
  u.nombre,
  u.email,
  COUNT(p.id) AS total_pedidos,
  COALESCE(SUM(p.total), 0) AS gasto_total,
  COALESCE(AVG(p.total), 0) AS gasto_promedio,
  MAX(p.creado_en) AS ultimo_pedido
FROM usuarios u
JOIN pedidos p ON p.cliente_id = u.id
WHERE u.rol = 'cliente' AND p.estado = 'entregado'
GROUP BY u.id, u.nombre, u.email
ORDER BY total_pedidos DESC;

CREATE OR REPLACE VIEW vista_rendimiento_repartidores AS
SELECT
  r.usuario_id AS repartidor_id,
  u.nombre,
  r.entregas_completadas,
  COUNT(p.id) AS pedidos_asignados,
  COALESCE(AVG(EXTRACT(EPOCH FROM (p.entregado_en - p.en_camino_en))/60), 0) AS minutos_promedio_entrega,
  COUNT(*) FILTER (WHERE p.estado = 'cancelado') AS cancelaciones
FROM repartidores r
JOIN usuarios u ON u.id = r.usuario_id
LEFT JOIN pedidos p ON p.repartidor_id = r.usuario_id
GROUP BY r.usuario_id, u.nombre, r.entregas_completadas
ORDER BY r.entregas_completadas DESC;