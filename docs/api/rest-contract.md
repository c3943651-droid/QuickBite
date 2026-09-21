# Contrato de API REST - QuickBite v1.0

**Versión:** 5.0 | **Fecha:** 14/09/2026 | **Estado:** Aprobado

---

## 1. Información General

| Aspecto | Definición |
|---------|------------|
| **Base URL Producción** | `https://<dominio>/api/v1` |
| **Base URL Desarrollo** | `https://localhost:5001/api/v1` |
| **Protocolo** | HTTPS (TLS 1.2+) |
| **Formato** | JSON (UTF-8) |
| **Autenticación** | JWT Bearer Token |
| **Versionado** | En URL (`/api/v1`) |

---

## 2. Autenticación

### 2.1 Tokens

| Token | Duración | Almacenamiento | Renovación |
|-------|----------|----------------|------------|
| Access Token | 1 hora | Memoria (cliente) | Via Refresh Token |
| Refresh Token | 7 días | BD (hasheado BCrypt) | Rotación en cada uso |

### 2.2 Cabeceras Requeridas

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

### 2.3 Flujo de Autenticación

1. `POST /auth/login` → Devuelve `accessToken` + `refreshToken`
2. Cada petición incluye `Authorization: Bearer <accessToken>`
3. Si 401 → `POST /auth/refresh` con `refreshToken` → Nuevo `accessToken`
4. `POST /auth/logout` → Revoca `refreshToken` en BD

---

## 3. Convenciones

### 3.1 Códigos de Estado HTTP

| Código | Significado |
|--------|-------------|
| 200 | Éxito |
| 201 | Creado |
| 204 | Sin contenido |
| 400 | Datos inválidos / Regla de negocio |
| 401 | No autenticado / Token expirado |
| 403 | Sin permisos |
| 404 | No encontrado |
| 409 | Conflicto (email duplicado, stock insuficiente) |
| 429 | Rate limit excedido |
| 500 | Error interno |
| 503 | Servicio no disponible |

### 3.2 Formato de Error Estándar

```json
{
  "timestamp": "2026-09-14T10:30:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Descripción legible del error",
  "path": "/api/v1/orders",
  "details": {
    "campo": "mensaje de validación"
  }
}
```

### 3.3 Paginación

**Parámetros:** `page` (default: 1), `limit` (default: 10, max: 50)

**Respuesta:**
```json
{
  "data": [...],
  "meta": {
    "total": 100,
    "page": 1,
    "limit": 10,
    "totalPages": 10
  }
}
```

### 3.4 Fechas y Números

- Fechas: ISO 8601 UTC (`2026-09-14T10:30:00Z`)
- UUIDs: v4 string (`"550e8400-e29b-41d4-a716-446655440000"`)
- Monetarios: Decimal 2 posiciones (`12.50`)

---

## 4. Endpoints por Recurso

### 4.1 Health Check

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| GET | `/health` | Público | Health check para cron jobs |

---

### 4.2 Autenticación (`/auth`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| POST | `/auth/register` | No | Público | Registro de usuario |
| POST | `/auth/login` | No | Público | Inicio de sesión |
| POST | `/auth/refresh` | No | Público | Renovar access token |
| POST | `/auth/logout` | JWT | Todos | Cerrar sesión |
| POST | `/auth/forgot-password` | No | Público | Solicitar recovery |
| POST | `/auth/reset-password` | No | Público | Restablecer contraseña |

**Registro:** Revela email duplicado (409) - ver decisión D-04  
**Recuperación:** Mensaje genérico siempre - ver decisión D-04

---

### 4.3 Usuarios (`/users`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/users/profile` | JWT | Todos | Perfil del usuario |
| PUT | `/users/profile` | JWT | Todos | Actualizar perfil |
| PUT | `/users/change-password` | JWT | Todos | Cambiar contraseña |
| GET | `/users/addresses` | JWT | Cliente | Listar direcciones |
| POST | `/users/addresses` | JWT | Cliente | Crear dirección |
| PUT | `/users/addresses/{id}` | JWT | Cliente | Actualizar dirección |
| DELETE | `/users/addresses/{id}` | JWT | Cliente | Eliminar dirección |
| PATCH | `/users/addresses/{id}/set-default` | JWT | Cliente | Marcar predeterminada |
| GET | `/users/sessions` | JWT | Todos | **Listar sesiones activas** |
| DELETE | `/users/sessions/{id}` | JWT | Todos | **Revocar sesión específica** |

---

### 4.4 Catálogo (`/categories`, `/products`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/categories` | No | Público | Listar categorías activas |
| GET | `/products` | No | Público | Listar productos con filtros |
| GET | `/products/{id}` | No | Público | Detalle de producto |
| GET | `/products/{id}/options` | No | Público | Opciones de producto |

**Filtros avanzados en `/products`:**
- `categoria_id` (UUID)
- `search` (string - búsqueda textual)
- `disponible` (boolean, default: true)
- `precio_min` / `precio_max` (numeric)
- `orden` (relevancia, precio_asc, precio_desc, nombre_asc, nombre_desc)

---

### 4.5 Carrito (`/cart`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/cart` | JWT | Cliente | Obtener carrito activo |
| POST | `/cart/items` | JWT | Cliente | Agregar item (también para reordenar) |
| PUT | `/cart/items/{itemId}` | JWT | Cliente | Modificar item |
| DELETE | `/cart/items/{itemId}` | JWT | Cliente | Eliminar item |
| DELETE | `/cart` | JWT | Cliente | Vaciar carrito |

---

### 4.6 Pedidos - Cliente (`/orders`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| POST | `/orders` | JWT | Cliente | Crear pedido desde carrito |
| GET | `/orders` | JWT | Cliente | Listar pedidos propios |
| GET | `/orders/{id}` | JWT | Cliente | Detalle de pedido |
| GET | `/orders/{id}/status` | JWT | Cliente | **Estado actual (polling 10s)** |
| PATCH | `/orders/{id}/cancel` | JWT | Cliente | Cancelar (pendiente/confirmado) |

---

### 4.7 Administración de Pedidos (`/admin/orders`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/admin/orders` | JWT | Admin | Listar todos (polling 30s) |
| GET | `/admin/orders/{id}` | JWT | Admin | Detalle completo |
| PATCH | `/admin/orders/{id}/status` | JWT | Admin | Cambiar estado |
| PATCH | `/admin/orders/{id}/assign` | JWT | Admin | **Asignar repartidor (asistido)** |
| PATCH | `/admin/orders/{id}/cancel` | JWT | Admin | Cancelar con motivo |
| GET | `/admin/dashboard` | JWT | Admin | **Métricas dashboard (polling 30s)** |

**Transiciones válidas de estado:**
```
pendiente → confirmado, cancelado
confirmado → preparando, cancelado
preparando → listo, cancelado
listo → en_camino, cancelado
en_camino → entregado
```

---

### 4.8 Administración de Productos (`/admin/products`, `/admin/categories`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| POST | `/admin/products` | JWT | Admin | Crear producto |
| PUT | `/admin/products/{id}` | JWT | Admin | Actualizar producto |
| DELETE | `/admin/products/{id}` | JWT | Admin | Eliminar lógico (desactivar) |
| PATCH | `/admin/products/{id}/availability` | JWT | Admin | Activar/desactivar |
| GET | `/admin/products/{id}/price-history` | JWT | Admin | Historial de precios |
| POST | `/admin/products/{id}/options` | JWT | Admin | Agregar opción |
| PUT | `/admin/products/{id}/options/{optionId}` | JWT | Admin | Actualizar opción |
| DELETE | `/admin/products/{id}/options/{optionId}` | JWT | Admin | Desactivar opción |
| PATCH | `/admin/products/{id}/stock` | JWT | Admin | Ajustar stock manual |
| POST | `/admin/categories` | JWT | Admin | Crear categoría |
| PUT | `/admin/categories/{id}` | JWT | Admin | Actualizar categoría |
| DELETE | `/admin/categories/{id}` | JWT | Admin | Desactivar categoría |

---

### 4.9 Administración de Repartidores (`/admin/delivery-persons`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/admin/delivery-persons` | JWT | Admin | Listar repartidores |
| POST | `/admin/delivery-persons` | JWT | Admin | Dar de alta repartidor |
| PUT | `/admin/delivery-persons/{id}` | JWT | Admin | Actualizar repartidor |
| PATCH | `/admin/delivery-persons/{id}/deactivate` | JWT | Admin | Desactivar repartidor |
| GET | `/admin/delivery-persons/{id}/history` | JWT | Admin | Historial de entregas |

---

### 4.10 Repartidor (`/delivery`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/delivery/available` | JWT | Repartidor | **Pedidos disponibles (polling 30s)** |
| POST | `/delivery/accept/{orderId}` | JWT | Repartidor | **Aceptar pedido (flujo principal)** |
| GET | `/delivery/active` | JWT | Repartidor | Pedido activo |
| POST | `/delivery/complete/{orderId}` | JWT | Repartidor | Marcar como entregado |
| GET | `/delivery/history` | JWT | Repartidor | Historial de entregas |
| GET | `/delivery/stats` | JWT | Repartidor | **Estadísticas personales** |

---

### 4.11 Notificaciones (`/notifications`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/notifications` | JWT | Todos | Listar notificaciones in-app |
| PATCH | `/notifications/{id}/read` | JWT | Todos | Marcar como leída |

> **Nota:** Endpoint de registro de dispositivo **NO IMPLEMENTADO** (ver D-01, D-02)

---

### 4.12 Reportes (`/admin/reports`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/admin/reports/sales-by-day` | JWT | Admin | Ventas por día |
| GET | `/admin/reports/top-products` | JWT | Admin | Productos más vendidos |
| GET | `/admin/reports/top-clients` | JWT | Admin | Clientes frecuentes |
| GET | `/admin/reports/delivery-performance` | JWT | Admin | Rendimiento repartidores |

---

### 4.13 Configuración (`/admin/config`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/admin/config` | JWT | Admin | Listar parámetros |
| PUT | `/admin/config/{key}` | JWT | Admin | Actualizar parámetro |

---

### 4.14 Auditoría (`/admin/audit`)

| Método | Ruta | Auth | Roles | Descripción |
|--------|------|------|-------|-------------|
| GET | `/admin/audit` | JWT | Admin | Consultar auditoría con filtros |

---

## 5. Polling - Endpoints y Frecuencias

| Endpoint | Cliente | Frecuencia | Decisión |
|----------|---------|------------|----------|
| `GET /orders/{id}/status` | App móvil RN (cliente) | 10 segundos | D-01 |
| `GET /admin/dashboard` | Panel admin | 30 segundos | D-01 |
| `GET /admin/orders` | Panel admin | 30 segundos | D-01 |
| `GET /delivery/available` | App móvil RN (repartidor) | 30 segundos | D-01 |

**Reglas de polling:**
- Inicia al entrar a la pantalla
- Se detiene al salir de la pantalla
- Se pausa en background
- Se detiene en estado final (entregado/cancelado)
- Backoff exponencial ante errores (max 3 reintentos)

---

## 6. Endpoints NO Implementados (Exclusiones Vinculantes)

| Endpoint | Motivo | Decisión |
|----------|--------|----------|
| `POST /devices/register` | Push reemplazado por polling | D-01, D-02 |

---

## 7. Requisitos Implementados Sin Endpoints Nuevos

| Requisito | Implementación |
|-----------|----------------|
| RF-02.6 Filtros avanzados | Parámetros en `GET /products` |
| RF-02.7 Historial búsquedas | Almacenamiento local en dispositivo (D-13) |
| RF-04.4 Reordenar pedido | Múltiples `POST /cart/items` desde cliente |

---

## 8. Referencias

- **Documento maestro:** `docs/04 — Contrato de API REST.md`
- **Decisiones canónicas:** `docs/05 — Decisiones Canónicas y Simplificaciones.md`
- **Modelo de datos:** `docs/03 — Modelo de Datos.md`
- **Arquitectura:** `docs/02 — Arquitectura del Sistema.md`
- **OpenAPI 3.0:** `openapi.yaml` (artefacto separado)