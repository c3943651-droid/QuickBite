**Versión:** 4.1
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Backend, base de datos
**Depende de:** 00, 01, 02
**Referenciado por:** 04, 06, 07, 07.1, 08, 08.1, 12

---

## 1. Introducción

Este documento define el modelo de datos de QuickBite implementado sobre PostgreSQL 15 en Supabase. Incluye:

- Diagrama entidad-relación (textual).
- Tipos enumerados.
- Diccionario completo de tablas, columnas, tipos, restricciones e índices.
- Lista de funciones, triggers y vistas con su propósito.
- DDL SQL completo embebido.
- Seed data inicial.

Las decisiones transversales que afectan al modelo (tabla `dispositivos_push` no usada, lógica en triggers, auditoría diferenciada, modelo mono-sucursal) se documentan en el documento 05.

---

## 2. Diagrama Entidad-Relación (Textual)

### 2.1. Agrupaciones Funcionales

| Agrupación | Tablas |
| :--- | :--- |
| Identidad y acceso | usuarios, direcciones, repartidores, tokens_refresco, tokens_recuperacion_password, notificaciones, auditoria_acciones, dispositivos_push |
| Catálogo e inventario | categorias, productos, producto_precios_historicos, inventario, producto_opciones |
| Carrito | carritos, carrito_items, carrito_item_opciones |
| Pedidos | pedidos, pedido_items, pedido_item_opciones, pedido_historial_estados |
| Configuración | configuracion_sistema, metodos_pago |

### 2.2. Relaciones Principales

| Origen | Destino | Cardinalidad | Descripción |
| :--- | :--- | :--- | :--- |
| usuarios | direcciones | 1:N | Un cliente tiene varias direcciones |
| usuarios | repartidores | 1:1 | Solo los usuarios con rol repartidor tienen registro |
| usuarios | tokens_refresco | 1:N | Un usuario puede tener varios tokens activos |
| usuarios | tokens_recuperacion_password | 1:N | Tokens de recuperación de contraseña |
| usuarios | notificaciones | 1:N | Notificaciones in-app del usuario |
| usuarios | auditoria_acciones | 1:N | Acciones críticas registradas |
| usuarios | carritos | 1:1 | Carrito activo del cliente |
| usuarios | pedidos (cliente) | 1:N | Pedidos realizados como cliente |
| repartidores | pedidos | 1:N | Pedidos asignados al repartidor |
| categorias | productos | 1:N | Productos por categoría |
| productos | producto_precios_historicos | 1:N | Historial de cambios de precio |
| productos | inventario | 1:1 | Stock del producto |
| productos | producto_opciones | 1:N | Opciones personalizables |
| carritos | carrito_items | 1:N | Items del carrito |
| carrito_items | carrito_item_opciones | 1:N | Opciones seleccionadas |
| pedidos | pedido_items | 1:N | Items del pedido |
| pedidos | pedido_historial_estados | 1:N | Historial de cambios de estado |
| pedidos | notificaciones | 1:N | Notificaciones asociadas a un pedido |
| pedido_items | pedido_item_opciones | 1:N | Opciones históricas del item |

---

## 3. Tipos Enumerados

| Tipo | Valores | Descripción |
| :--- | :--- | :--- |
| rol_usuario | cliente, administrador, repartidor | Rol del usuario en el sistema |
| estado_pedido | pendiente, confirmado, preparando, listo, en_camino, entregado, cancelado | Ciclo de vida del pedido |
| metodo_pago | efectivo, tarjeta | Métodos de pago simulados |
| estado_repartidor | disponible, ocupado, inactivo | Estado operativo del repartidor |
| tipo_notificacion | pedido_nuevo, cambio_estado, asignacion, sistema, recordatorio | Categoría de la notificación |
| plataforma_dispositivo | android, ios, web | Plataforma del dispositivo (no usado en v1.0) |

---

## 4. Diccionario de Datos

### 4.1. usuarios

Almacena la identidad de todos los actores del sistema.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK, default gen_random_uuid() | Identificador |
| nombre | VARCHAR(150) | NOT NULL | Nombre completo |
| email | VARCHAR(255) | NOT NULL, UNIQUE, formato email | Correo de acceso |
| password_hash | VARCHAR(255) | NOT NULL | Hash de contraseña |
| telefono | VARCHAR(20) | NULL | Teléfono de contacto |
| rol | rol_usuario | NOT NULL | Rol del usuario |
| activo | BOOLEAN | NOT NULL, default TRUE | Cuenta activa |
| intentos_fallidos | SMALLINT | NOT NULL, default 0 | Intentos fallidos de login |
| bloqueado_hasta | TIMESTAMPTZ | NULL | Bloqueo temporal |
| ultimo_login | TIMESTAMPTZ | NULL | Fecha del último login |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de creación |
| actualizado_en | TIMESTAMPTZ | NOT NULL, default now() | Última modificación |

Índices: `idx_usuarios_rol`, `idx_usuarios_email`, `idx_usuarios_activo` (parcial).

Trigger: `trg_usuarios_actualizado_en`.

### 4.2. direcciones

Direcciones de entrega de los clientes.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| usuario_id | UUID | FK usuarios, ON DELETE CASCADE | Propietario |
| alias | VARCHAR(50) | NULL | Nombre corto |
| calle | VARCHAR(200) | NOT NULL | Calle y número |
| numero | VARCHAR(20) | NULL | Número interior/exterior |
| referencia | VARCHAR(255) | NULL | Referencias para el repartidor |
| ciudad | VARCHAR(100) | NOT NULL | Ciudad |
| latitud | NUMERIC(10,7) | NULL | Coordenada de latitud |
| longitud | NUMERIC(10,7) | NULL | Coordenada de longitud |
| es_predeterminada | BOOLEAN | NOT NULL, default FALSE | Dirección por defecto |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de creación |

Índices: `idx_direcciones_usuario_id`, `idx_direcciones_ciudad`, `uq_direccion_predeterminada_por_usuario` (único parcial).

### 4.3. repartidores

Extiende la información de usuarios con rol repartidor.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| usuario_id | UUID | PK, FK usuarios, ON DELETE CASCADE | Usuario repartidor |
| estado_disponibilidad | estado_repartidor | NOT NULL, default inactivo | Estado operativo |
| vehiculo | VARCHAR(50) | NULL | Tipo de vehículo |
| entregas_completadas | INTEGER | NOT NULL, default 0 | Contador de entregas |
| fecha_alta | TIMESTAMPTZ | NOT NULL, default now() | Fecha de alta |

Índices: `idx_repartidores_estado`, `idx_repartidores_entregas`.

Trigger: `trg_validar_rol_repartidor`.

### 4.4. tokens_refresco

Tokens de refresco emitidos para renovar sesiones.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| usuario_id | UUID | FK usuarios, ON DELETE CASCADE | Usuario |
| token_hash | VARCHAR(255) | NOT NULL | Hash del token |
| expira_en | TIMESTAMPTZ | NOT NULL | Expiración |
| revocado | BOOLEAN | NOT NULL, default FALSE | Revocado por logout |
| ip_origen | VARCHAR(45) | NULL | IP de emisión |
| user_agent | VARCHAR(255) | NULL | Navegador o dispositivo |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de emisión |

Índices: `idx_tokens_refresco_usuario_id`, `idx_tokens_refresco_expiracion` (parcial).

### 4.5. tokens_recuperacion_password

Tokens de un solo uso para recuperación de contraseña.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| usuario_id | UUID | FK usuarios, ON DELETE CASCADE | Usuario |
| token_hash | VARCHAR(255) | NOT NULL | Hash del token |
| expira_en | TIMESTAMPTZ | NOT NULL | Expiración |
| usado | BOOLEAN | NOT NULL, default FALSE | Marca de uso |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de creación |

### 4.6. dispositivos_push

Tabla conservada en el esquema pero no usada en v1.0. No se mapea en el ORM. No se puebla.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| usuario_id | UUID | FK usuarios, ON DELETE CASCADE | Usuario |
| token | VARCHAR(255) | NOT NULL | Token del dispositivo |
| plataforma | plataforma_dispositivo | NOT NULL, default android | Plataforma |
| activo | BOOLEAN | NOT NULL, default TRUE | Vigencia |
| registrado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de registro |

Restricción: UNIQUE (usuario_id, token).

Referencia: 05#D-02.

### 4.7. categorias

Categorías de productos.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| nombre | VARCHAR(100) | NOT NULL, UNIQUE | Nombre |
| descripcion | VARCHAR(255) | NULL | Descripción |
| orden | SMALLINT | NOT NULL, default 0 | Orden de visualización |
| activo | BOOLEAN | NOT NULL, default TRUE | Visible |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de creación |

### 4.8. productos

Catálogo de productos.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| categoria_id | UUID | FK categorias, ON DELETE SET NULL | Categoría |
| nombre | VARCHAR(150) | NOT NULL | Nombre |
| descripcion | TEXT | NULL | Descripción detallada |
| precio | NUMERIC(10,2) | NOT NULL, >= 0 | Precio actual |
| imagen_url | VARCHAR(500) | NULL | URL de la imagen |
| disponible | BOOLEAN | NOT NULL, default TRUE | Disponible para venta |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de creación |
| actualizado_en | TIMESTAMPTZ | NOT NULL, default now() | Última modificación |

Índices: `idx_productos_categoria_id`, `idx_productos_disponible` (parcial), `idx_productos_precio`, `idx_productos_nombre_trgm` (GIN con pg_trgm).

Trigger: `trg_productos_actualizado_en`.

### 4.9. producto_precios_historicos

Auditoría de cambios de precio.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| producto_id | UUID | FK productos, ON DELETE CASCADE | Producto |
| precio_anterior | NUMERIC(10,2) | NOT NULL | Precio previo |
| precio_nuevo | NUMERIC(10,2) | NOT NULL | Precio nuevo |
| usuario_id | UUID | FK usuarios, ON DELETE SET NULL | Quién cambió |
| motivo | VARCHAR(255) | NULL | Motivo |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha |

### 4.10. inventario

Stock de cada producto.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| producto_id | UUID | PK, FK productos, ON DELETE CASCADE | Producto |
| stock | INTEGER | NOT NULL, default 0, >= 0 | Cantidad disponible |
| stock_minimo | INTEGER | NOT NULL, default 0 | Mínimo para alerta |
| ultima_actualizacion | TIMESTAMPTZ | NOT NULL, default now() | Última actualización |
| actualizado_por | UUID | FK usuarios, ON DELETE SET NULL | Quién actualizó |

Índice: `idx_inventario_stock_bajo`.

### 4.11. metodos_pago

Catálogo de métodos de pago.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| nombre | VARCHAR(50) | NOT NULL, UNIQUE | Nombre |
| descripcion | VARCHAR(200) | NULL | Descripción |
| activo | BOOLEAN | NOT NULL, default TRUE | Habilitado |

Datos iniciales: efectivo, tarjeta.

### 4.12. producto_opciones

Opciones personalizables de un producto.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| producto_id | UUID | FK productos, ON DELETE CASCADE | Producto |
| nombre | VARCHAR(100) | NOT NULL | Nombre |
| precio_adicional | NUMERIC(10,2) | NOT NULL, default 0, >= 0 | Costo adicional |
| activo | BOOLEAN | NOT NULL, default TRUE | Disponible |

### 4.13. carritos

Carrito activo de cada cliente.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| usuario_id | UUID | NOT NULL, UNIQUE, FK usuarios, ON DELETE CASCADE | Cliente |
| actualizado_en | TIMESTAMPTZ | NOT NULL, default now() | Última modificación |
| ultimo_acceso | TIMESTAMPTZ | NOT NULL, default now() | Último acceso |
| expira_en | TIMESTAMPTZ | NOT NULL, default now() + 24h | Expiración |
| estado | VARCHAR(20) | NOT NULL, default activo, IN (activo, abandonado, convertido) | Estado |

Índices: `idx_carritos_usuario_id`, `idx_carritos_expiracion` (parcial), `idx_carritos_estado`.

### 4.14. carrito_items

Items dentro de un carrito.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| carrito_id | UUID | FK carritos, ON DELETE CASCADE | Carrito |
| producto_id | UUID | FK productos, ON DELETE CASCADE | Producto |
| cantidad | SMALLINT | NOT NULL, > 0 | Cantidad |
| observaciones | VARCHAR(255) | NULL | Notas del cliente |
| agregado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de agregado |

Trigger: `trg_actualizar_carrito_acceso`.

### 4.15. carrito_item_opciones

Opciones seleccionadas por item de carrito.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| carrito_item_id | UUID | FK carrito_items, ON DELETE CASCADE | Item |
| opcion_id | UUID | FK producto_opciones, ON DELETE CASCADE | Opción |

### 4.16. pedidos

Tabla central del sistema.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| numero_pedido | VARCHAR(20) | NOT NULL, UNIQUE | Número legible |
| cliente_id | UUID | NOT NULL, FK usuarios | Cliente |
| repartidor_id | UUID | FK repartidores, ON DELETE SET NULL | Repartidor asignado |
| direccion_id | UUID | FK direcciones, ON DELETE SET NULL | Dirección original |
| direccion_entrega_snapshot | TEXT | NOT NULL | Copia textual de la dirección |
| estado | estado_pedido | NOT NULL, default pendiente | Estado actual |
| metodo_pago | metodo_pago | NOT NULL | Método elegido |
| metodo_pago_id | UUID | FK metodos_pago | Referencia al catálogo |
| subtotal | NUMERIC(10,2) | NOT NULL, >= 0 | Suma de items |
| costo_envio | NUMERIC(10,2) | NOT NULL, default 0, >= 0 | Costo de envío |
| total | NUMERIC(10,2) | NOT NULL, >= 0 | Total |
| motivo_cancelacion | VARCHAR(255) | NULL | Motivo de cancelación |
| confirmado_en | TIMESTAMPTZ | NULL | Timestamp |
| preparando_en | TIMESTAMPTZ | NULL | Timestamp |
| listo_en | TIMESTAMPTZ | NULL | Timestamp |
| en_camino_en | TIMESTAMPTZ | NULL | Timestamp |
| entregado_en | TIMESTAMPTZ | NULL | Timestamp |
| cancelado_en | TIMESTAMPTZ | NULL | Timestamp |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de creación |
| actualizado_en | TIMESTAMPTZ | NOT NULL, default now() | Última modificación |

Índices: por cliente, repartidor, estado, fecha, número y compuestos.

Triggers: `trg_pedidos_actualizado_en`, `trg_validar_transicion_pedido`, `trg_registrar_historial_pedido`, `trg_generar_numero_pedido`, `trg_validar_stock_pedido`, `trg_descontar_stock_pedido`, `trg_restaurar_stock_pedido`, `trg_incrementar_entregas_repartidor`.

### 4.17. pedido_items

Items de un pedido con precio histórico.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| pedido_id | UUID | FK pedidos, ON DELETE CASCADE | Pedido |
| producto_id | UUID | FK productos, ON DELETE SET NULL | Producto original |
| nombre_producto | VARCHAR(150) | NOT NULL | Nombre histórico |
| precio_unitario | NUMERIC(10,2) | NOT NULL, >= 0 | Precio al momento |
| cantidad | SMALLINT | NOT NULL, > 0 | Cantidad |
| observaciones | VARCHAR(255) | NULL | Notas |
| subtotal | NUMERIC(10,2) | NOT NULL, >= 0 | precio * cantidad |

Índices: `uq_pedido_items_producto`, `idx_pedido_items_pedido_id`, `idx_pedido_items_producto`.

### 4.18. pedido_item_opciones

Opciones históricas de un item del pedido.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| pedido_item_id | UUID | FK pedido_items, ON DELETE CASCADE | Item |
| nombre_opcion | VARCHAR(100) | NOT NULL | Nombre histórico |
| precio_adicional | NUMERIC(10,2) | NOT NULL, default 0 | Precio histórico |

### 4.19. pedido_historial_estados

Auditoría de cambios de estado del pedido.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| pedido_id | UUID | FK pedidos, ON DELETE CASCADE | Pedido |
| estado_anterior | estado_pedido | NULL | Estado previo |
| estado_nuevo | estado_pedido | NOT NULL | Estado nuevo |
| usuario_id | UUID | FK usuarios | Quién cambió |
| comentario | VARCHAR(255) | NULL | Comentario |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha |

### 4.20. notificaciones

Notificaciones in-app.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| usuario_id | UUID | FK usuarios, ON DELETE CASCADE | Destinatario |
| tipo | tipo_notificacion | NOT NULL | Categoría |
| titulo | VARCHAR(150) | NOT NULL | Título |
| mensaje | VARCHAR(500) | NOT NULL | Cuerpo |
| pedido_id | UUID | FK pedidos, ON DELETE CASCADE | Pedido relacionado |
| leido | BOOLEAN | NOT NULL, default FALSE | Estado |
| leido_en | TIMESTAMPTZ | NULL | Fecha de lectura |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de creación |

### 4.21. auditoria_acciones

Registro de acciones críticas.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| usuario_id | UUID | FK usuarios, ON DELETE SET NULL | Quién actuó |
| accion | VARCHAR(100) | NOT NULL | Acción realizada |
| entidad | VARCHAR(50) | NOT NULL | Entidad afectada |
| entidad_id | UUID | NULL | ID de la entidad |
| detalles | JSONB | NULL | Datos adicionales |
| ip_origen | VARCHAR(45) | NULL | IP |
| user_agent | TEXT | NULL | Navegador o dispositivo |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha |

Referencia: 05#D-03 para acciones diferenciadas de asignación de repartidor.

### 4.22. configuracion_sistema

Parámetros globales configurables.

| Columna | Tipo | Restricciones | Descripción |
| :--- | :--- | :--- | :--- |
| id | UUID | PK | Identificador |
| clave | VARCHAR(50) | NOT NULL, UNIQUE | Nombre del parámetro |
| valor | TEXT | NOT NULL | Valor |
| descripcion | VARCHAR(255) | NULL | Descripción |
| editable | BOOLEAN | NOT NULL, default TRUE | Editable por admin |
| creado_en | TIMESTAMPTZ | NOT NULL, default now() | Fecha de creación |
| actualizado_en | TIMESTAMPTZ | NOT NULL, default now() | Última modificación |

---

## 5. Funciones, Triggers y Vistas

### 5.1. Funciones y Triggers

| Función | Trigger | Evento | Propósito |
| :--- | :--- | :--- | :--- |
| set_actualizado_en() | trg_usuarios_actualizado_en | BEFORE UPDATE en usuarios | Actualiza timestamp |
| set_actualizado_en() | trg_productos_actualizado_en | BEFORE UPDATE en productos | Actualiza timestamp |
| set_actualizado_en() | trg_pedidos_actualizado_en | BEFORE UPDATE en pedidos | Actualiza timestamp |
| validar_rol_repartidor() | trg_validar_rol_repartidor | BEFORE INSERT en repartidores | Exige rol repartidor |
| actualizar_carrito_acceso() | trg_actualizar_carrito_acceso | AFTER INSERT/UPDATE en carrito_items | Actualiza acceso del carrito |
| validar_transicion_pedido() | trg_validar_transicion_pedido | BEFORE UPDATE en pedidos | Valida transición y asigna timestamps |
| registrar_historial_pedido() | trg_registrar_historial_pedido | AFTER INSERT/UPDATE en pedidos | Registra historial |
| generar_numero_pedido() | trg_generar_numero_pedido | BEFORE INSERT en pedidos | Genera número único |
| validar_stock_pedido() | trg_validar_stock_pedido | BEFORE UPDATE en pedidos | Valida stock |
| descontar_stock_pedido() | trg_descontar_stock_pedido | AFTER UPDATE en pedidos | Descuenta stock |
| restaurar_stock_pedido() | trg_restaurar_stock_pedido | AFTER UPDATE en pedidos | Restaura stock al cancelar |
| incrementar_entregas_repartidor() | trg_incrementar_entregas_repartidor | AFTER UPDATE en pedidos | Incrementa contador y libera repartidor |
| validar_transicion_repartidor() | trg_validar_transicion_repartidor | BEFORE UPDATE en repartidores | Evita disponible con pedidos activos |

### 5.2. Vistas

| Vista | Propósito |
| :--- | :--- |
| vista_pedidos_por_dia | Métricas diarias de pedidos, ingresos y ticket promedio |
| vista_productos_mas_vendidos | Ranking por unidades vendidas e ingresos |
| vista_clientes_frecuentes | Ranking por número de pedidos y gasto total |
| vista_rendimiento_repartidores | Entregas, tiempo promedio y cancelaciones |

---

## 6. DDL SQL Completo

```sql
-- =====================================================================
-- QuickBite v1.0 — Esquema completo
-- PostgreSQL 15 (Supabase)
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ---------------------------------------------------------------------
-- Tipos enumerados
-- ---------------------------------------------------------------------
CREATE TYPE rol_usuario AS ENUM ('cliente', 'administrador', 'repartidor');
CREATE TYPE estado_pedido AS ENUM ('pendiente', 'confirmado', 'preparando', 'listo', 'en_camino', 'entregado', 'cancelado');
CREATE TYPE metodo_pago AS ENUM ('efectivo', 'tarjeta');
CREATE TYPE estado_repartidor AS ENUM ('disponible', 'ocupado', 'inactivo');
CREATE TYPE tipo_notificacion AS ENUM ('pedido_nuevo', 'cambio_estado', 'asignacion', 'sistema', 'recordatorio');
CREATE TYPE plataforma_dispositivo AS ENUM ('android', 'ios', 'web');

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

-- ---------------------------------------------------------------------
-- usuarios
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre VARCHAR(150) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE CHECK (email ~* '^[^@]+@[^@]+\.[^@]+$'),
  password_hash VARCHAR(255) NOT NULL,
  telefono VARCHAR(20),
  rol rol_usuario NOT NULL,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  intentos_fallidos SMALLINT NOT NULL DEFAULT 0,
  bloqueado_hasta TIMESTAMPTZ,
  ultimo_login TIMESTAMPTZ,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_usuarios_rol ON usuarios(rol);
CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_usuarios_activo ON usuarios(activo) WHERE activo = TRUE;
CREATE TRIGGER trg_usuarios_actualizado_en BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

-- ---------------------------------------------------------------------
-- direcciones
-- ---------------------------------------------------------------------
CREATE TABLE direcciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  alias VARCHAR(50),
  calle VARCHAR(200) NOT NULL,
  numero VARCHAR(20),
  referencia VARCHAR(255),
  ciudad VARCHAR(100) NOT NULL,
  latitud NUMERIC(10,7),
  longitud NUMERIC(10,7),
  es_predeterminada BOOLEAN NOT NULL DEFAULT FALSE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_direcciones_usuario_id ON direcciones(usuario_id);
CREATE INDEX idx_direcciones_ciudad ON direcciones(ciudad);
CREATE UNIQUE INDEX uq_direccion_predeterminada_por_usuario
  ON direcciones(usuario_id) WHERE es_predeterminada = TRUE;

-- ---------------------------------------------------------------------
-- repartidores
-- ---------------------------------------------------------------------
CREATE TABLE repartidores (
  usuario_id UUID PRIMARY KEY REFERENCES usuarios(id) ON DELETE CASCADE,
  estado_disponibilidad estado_repartidor NOT NULL DEFAULT 'inactivo',
  vehiculo VARCHAR(50),
  entregas_completadas INTEGER NOT NULL DEFAULT 0,
  fecha_alta TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_repartidores_estado ON repartidores(estado_disponibilidad);
CREATE INDEX idx_repartidores_entregas ON repartidores(entregas_completadas DESC);

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

-- ---------------------------------------------------------------------
-- tokens_refresco
-- ---------------------------------------------------------------------
CREATE TABLE tokens_refresco (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expira_en TIMESTAMPTZ NOT NULL,
  revocado BOOLEAN NOT NULL DEFAULT FALSE,
  ip_origen VARCHAR(45),
  user_agent VARCHAR(255),
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_tokens_refresco_usuario_id ON tokens_refresco(usuario_id);
CREATE INDEX idx_tokens_refresco_expiracion ON tokens_refresco(expira_en)
  WHERE revocado = FALSE;

-- ---------------------------------------------------------------------
-- tokens_recuperacion_password
-- ---------------------------------------------------------------------
CREATE TABLE tokens_recuperacion_password (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  token_hash VARCHAR(255) NOT NULL,
  expira_en TIMESTAMPTZ NOT NULL,
  usado BOOLEAN NOT NULL DEFAULT FALSE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- dispositivos_push (no usada en v1.0)
-- ---------------------------------------------------------------------
CREATE TABLE dispositivos_push (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  token VARCHAR(255) NOT NULL,
  plataforma plataforma_dispositivo NOT NULL DEFAULT 'android',
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  registrado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (usuario_id, token)
);

-- ---------------------------------------------------------------------
-- categorias
-- ---------------------------------------------------------------------
CREATE TABLE categorias (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion VARCHAR(255),
  orden SMALLINT NOT NULL DEFAULT 0,
  activo BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- productos
-- ---------------------------------------------------------------------
CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  categoria_id UUID REFERENCES categorias(id) ON DELETE SET NULL,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  precio NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
  imagen_url VARCHAR(500),
  disponible BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_productos_categoria_id ON productos(categoria_id);
CREATE INDEX idx_productos_disponible ON productos(disponible) WHERE disponible = TRUE;
CREATE INDEX idx_productos_precio ON productos(precio);
CREATE INDEX idx_productos_nombre_trgm ON productos USING GIN (lower(nombre) gin_trgm_ops);
CREATE TRIGGER trg_productos_actualizado_en BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

-- ---------------------------------------------------------------------
-- producto_precios_historicos
-- ---------------------------------------------------------------------
CREATE TABLE producto_precios_historicos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  precio_anterior NUMERIC(10,2) NOT NULL,
  precio_nuevo NUMERIC(10,2) NOT NULL,
  usuario_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
  motivo VARCHAR(255),
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- inventario
-- ---------------------------------------------------------------------
CREATE TABLE inventario (
  producto_id UUID PRIMARY KEY REFERENCES productos(id) ON DELETE CASCADE,
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  stock_minimo INTEGER NOT NULL DEFAULT 0,
  ultima_actualizacion TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_por UUID REFERENCES usuarios(id) ON DELETE SET NULL
);
CREATE INDEX idx_inventario_stock_bajo ON inventario(producto_id)
  WHERE stock <= stock_minimo;

-- ---------------------------------------------------------------------
-- metodos_pago
-- ---------------------------------------------------------------------
CREATE TABLE metodos_pago (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre VARCHAR(50) NOT NULL UNIQUE,
  descripcion VARCHAR(200),
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------
-- producto_opciones
-- ---------------------------------------------------------------------
CREATE TABLE producto_opciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  nombre VARCHAR(100) NOT NULL,
  precio_adicional NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (precio_adicional >= 0),
  activo BOOLEAN NOT NULL DEFAULT TRUE
);

-- ---------------------------------------------------------------------
-- carritos
-- ---------------------------------------------------------------------
CREATE TABLE carritos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  ultimo_acceso TIMESTAMPTZ NOT NULL DEFAULT now(),
  expira_en TIMESTAMPTZ NOT NULL DEFAULT now() + INTERVAL '24 hours',
  estado VARCHAR(20) NOT NULL DEFAULT 'activo'
    CHECK (estado IN ('activo','abandonado','convertido'))
);
CREATE INDEX idx_carritos_usuario_id ON carritos(usuario_id);
CREATE INDEX idx_carritos_expiracion ON carritos(expira_en) WHERE estado = 'activo';
CREATE INDEX idx_carritos_estado ON carritos(estado);

-- ---------------------------------------------------------------------
-- carrito_items
-- ---------------------------------------------------------------------
CREATE TABLE carrito_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carrito_id UUID NOT NULL REFERENCES carritos(id) ON DELETE CASCADE,
  producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  cantidad SMALLINT NOT NULL CHECK (cantidad > 0),
  observaciones VARCHAR(255),
  agregado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

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
-- carrito_item_opciones
-- ---------------------------------------------------------------------
CREATE TABLE carrito_item_opciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  carrito_item_id UUID NOT NULL REFERENCES carrito_items(id) ON DELETE CASCADE,
  opcion_id UUID NOT NULL REFERENCES producto_opciones(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- pedidos
-- ---------------------------------------------------------------------
CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  numero_pedido VARCHAR(20) NOT NULL UNIQUE,
  cliente_id UUID NOT NULL REFERENCES usuarios(id),
  repartidor_id UUID REFERENCES repartidores(usuario_id) ON DELETE SET NULL,
  direccion_id UUID REFERENCES direcciones(id) ON DELETE SET NULL,
  direccion_entrega_snapshot TEXT NOT NULL,
  estado estado_pedido NOT NULL DEFAULT 'pendiente',
  metodo_pago metodo_pago NOT NULL,
  metodo_pago_id UUID REFERENCES metodos_pago(id),
  subtotal NUMERIC(10,2) NOT NULL CHECK (subtotal >= 0),
  costo_envio NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (costo_envio >= 0),
  total NUMERIC(10,2) NOT NULL CHECK (total >= 0),
  motivo_cancelacion VARCHAR(255),
  confirmado_en TIMESTAMPTZ,
  preparando_en TIMESTAMPTZ,
  listo_en TIMESTAMPTZ,
  en_camino_en TIMESTAMPTZ,
  entregado_en TIMESTAMPTZ,
  cancelado_en TIMESTAMPTZ,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_repartidor ON pedidos(repartidor_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_creado ON pedidos(creado_en DESC);
CREATE INDEX idx_pedidos_numero ON pedidos(numero_pedido);
CREATE INDEX idx_pedidos_estado_fecha ON pedidos(estado, creado_en DESC);

-- ---------------------------------------------------------------------
-- pedido_items
-- ---------------------------------------------------------------------
CREATE TABLE pedido_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  producto_id UUID REFERENCES productos(id) ON DELETE SET NULL,
  nombre_producto VARCHAR(150) NOT NULL,
  precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
  cantidad SMALLINT NOT NULL CHECK (cantidad > 0),
  observaciones VARCHAR(255),
  subtotal NUMERIC(10,2) NOT NULL CHECK (subtotal >= 0)
);
CREATE INDEX idx_pedido_items_pedido_id ON pedido_items(pedido_id);
CREATE INDEX idx_pedido_items_producto ON pedido_items(producto_id);
CREATE UNIQUE INDEX uq_pedido_items_producto ON pedido_items(pedido_id, producto_id)
  WHERE producto_id IS NOT NULL;

-- ---------------------------------------------------------------------
-- pedido_item_opciones
-- ---------------------------------------------------------------------
CREATE TABLE pedido_item_opciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_item_id UUID NOT NULL REFERENCES pedido_items(id) ON DELETE CASCADE,
  nombre_opcion VARCHAR(100) NOT NULL,
  precio_adicional NUMERIC(10,2) NOT NULL DEFAULT 0
);

-- ---------------------------------------------------------------------
-- pedido_historial_estados
-- ---------------------------------------------------------------------
CREATE TABLE pedido_historial_estados (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  estado_anterior estado_pedido,
  estado_nuevo estado_pedido NOT NULL,
  usuario_id UUID REFERENCES usuarios(id),
  comentario VARCHAR(255),
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- notificaciones
-- ---------------------------------------------------------------------
CREATE TABLE notificaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  tipo tipo_notificacion NOT NULL,
  titulo VARCHAR(150) NOT NULL,
  mensaje VARCHAR(500) NOT NULL,
  pedido_id UUID REFERENCES pedidos(id) ON DELETE CASCADE,
  leido BOOLEAN NOT NULL DEFAULT FALSE,
  leido_en TIMESTAMPTZ,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- auditoria_acciones
-- ---------------------------------------------------------------------
CREATE TABLE auditoria_acciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES usuarios(id) ON DELETE SET NULL,
  accion VARCHAR(100) NOT NULL,
  entidad VARCHAR(50) NOT NULL,
  entidad_id UUID,
  detalles JSONB,
  ip_origen VARCHAR(45),
  user_agent TEXT,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_auditoria_usuario ON auditoria_acciones(usuario_id);
CREATE INDEX idx_auditoria_entidad ON auditoria_acciones(entidad, entidad_id);
CREATE INDEX idx_auditoria_fecha ON auditoria_acciones(creado_en DESC);

-- ---------------------------------------------------------------------
-- configuracion_sistema
-- ---------------------------------------------------------------------
CREATE TABLE configuracion_sistema (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clave VARCHAR(50) NOT NULL UNIQUE,
  valor TEXT NOT NULL,
  descripcion VARCHAR(255),
  editable BOOLEAN NOT NULL DEFAULT TRUE,
  creado_en TIMESTAMPTZ NOT NULL DEFAULT now(),
  actualizado_en TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_config_actualizado_en BEFORE UPDATE ON configuracion_sistema
  FOR EACH ROW EXECUTE FUNCTION set_actualizado_en();

-- ---------------------------------------------------------------------
-- Triggers de pedidos
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

CREATE OR REPLACE FUNCTION registrar_historial_pedido()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO pedido_historial_estados (pedido_id, estado_anterior, estado_nuevo, usuario_id)
    VALUES (NEW.id, NULL, NEW.estado, NEW.cliente_id);
  ELSIF TG_OP = 'UPDATE' AND OLD.estado IS DISTINCT FROM NEW.estado THEN
    INSERT INTO pedido_historial_estados (pedido_id, estado_anterior, estado_nuevo, usuario_id)
    VALUES (NEW.id, OLD.estado, NEW.estado, NEW.cliente_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_registrar_historial_pedido
  AFTER INSERT OR UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION registrar_historial_pedido();

CREATE SEQUENCE seq_numero_pedido;

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
-- Vistas
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
```

---

## 7. Seed Data

```sql
-- Métodos de pago
INSERT INTO metodos_pago (nombre, descripcion) VALUES
  ('efectivo', 'Pago en efectivo contra entrega'),
  ('tarjeta', 'Pago con tarjeta (simulado)');

-- Configuración del sistema
INSERT INTO configuracion_sistema (clave, valor, descripcion, editable) VALUES
  ('costo_envio_default', '2.00', 'Costo de envío por defecto', TRUE),
  ('tiempo_preparacion_estimado', '20', 'Minutos estimados de preparación', TRUE),
  ('tiempo_entrega_estimado', '15', 'Minutos estimados de entrega', TRUE),
  ('carrito_expiracion_horas', '24', 'Horas antes de expirar un carrito', TRUE),
  ('max_intentos_login', '5', 'Intentos fallidos antes de bloqueo', TRUE);

-- Categorías
INSERT INTO categorias (nombre, descripcion, orden) VALUES
  ('Hamburguesas', 'Hamburguesas clásicas y especiales', 1),
  ('Bebidas', 'Refrescos, jugos y aguas', 2),
  ('Postres', 'Postres y helados', 3);

-- Productos (ejemplo)
-- Los productos se insertan con imagen y stock; ver migración de seed.
```

---

## 8. Referencias a Decisiones Canónicas

| Decisión | Impacto en el modelo | Referencia |
| :--- | :--- | :--- |
| Tabla `dispositivos_push` no usada | Se conserva, no se mapea en ORM, no se puebla | 05#D-02 |
| Doble flujo de asignación de repartidor | Auditoría diferenciada con acciones `asignacion_auto` y `asignacion_asistida` | 05#D-03 |
| Lógica crítica en triggers | Reglas de estado, stock y contadores en el motor | 05#D-05 |
| Cloudinary | Campo `imagen_url` almacena URL externa | 05#D-06 |
| Modelo mono-sucursal | No hay tablas `sucursales` ni campos `sucursal_id` | 05#D-09 |

---

## 9. Glosario

| Término | Definición |
| :--- | :--- |
| DDL | Data Definition Language: sentencias SQL que definen el esquema |
| Snapshot | Copia textual de un dato al momento de una transacción |
| JSONB | Tipo de dato binario para JSON en PostgreSQL |
| GIN | Índice invertido generalizado, útil para búsquedas textuales |
| pg_trgm | Extensión de PostgreSQL para similitud de texto |
| Trigger | Función que se ejecuta automáticamente ante un evento |
| Vista | Consulta almacenada que se comporta como tabla virtual |
| ON DELETE CASCADE | Elimina registros hijos cuando se elimina el padre |
| ON DELETE SET NULL | Establece NULL en hijos cuando se elimina el padre |

---

**Fin del Documento 03.**