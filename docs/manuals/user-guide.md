**Versión:** 3.0
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Usuarios finales (clientes, administradores, repartidores), evaluadores, usuarios de prueba
**Depende de:** 00, 04, 05, 07, 07.1, 08, 08.1, 09
**Referenciado por:** —

---

## 1. Introducción

Este manual describe cómo usar QuickBite desde los tres perfiles que operan el sistema: cliente, administrador y repartidor. Cada sección incluye los flujos paso a paso, las pantallas involucradas y las acciones disponibles.

El manual está dirigido a los usuarios de prueba y al público objetivo de la demostración. No sustituye a la especificación de pantallas (documento 07.1) ni a la especificación de páginas del panel admin (documento 08.1), pero se apoya en ellas.

Las decisiones canónicas (polling, pagos simulados, historial de búsquedas local, APK firmado, etc.) residen en el documento 05. Cuando una función depende de una decisión, se referencia brevemente.

---

## 2. Requisitos Previos

### 2.1. Cliente y Repartidor

| Aspecto | Requisito |
| :--- | :--- |
| Dispositivo | Teléfono o tablet con Android 5.0 o superior |
| Instalación | APK firmado proporcionado por el equipo |
| Permisos | Acceso a internet; opcionalmente, cámara y almacenamiento para el avatar |
| Conexión | Wi-Fi o datos móviles |

### 2.2. Administrador

| Aspecto | Requisito |
| :--- | :--- |
| Dispositivo | Navegador moderno en escritorio o tablet |
| Navegadores compatibles | Chrome, Firefox, Edge o Safari (últimas versiones) |
| Conexión | Wi-Fi o datos móviles |

---

## 3. Manual del Cliente

### 3.1. Primer Acceso

#### 3.1.1. Registro

1. Abrir la aplicación QuickBite.
2. En la pantalla de bienvenida, tocar "Crear cuenta".
3. Completar el formulario:
   - Nombre completo.
   - Correo electrónico.
   - Teléfono (opcional).
   - Contraseña (mínimo 8 caracteres, con mayúscula, número y símbolo).
   - Confirmar contraseña.
4. Seleccionar el rol "Cliente".
5. Aceptar la política de privacidad.
6. Tocar "Registrarse".
7. Si los datos son correctos, el sistema crea la cuenta, envía un correo de bienvenida y redirige al inicio de sesión.

**Posibles mensajes:**

- "El correo ya está registrado" (si el email existe).
- "La contraseña no cumple con los requisitos".
- "Las contraseñas no coinciden".

#### 3.1.2. Inicio de Sesión

1. En la pantalla de bienvenida, tocar "Iniciar sesión".
2. Ingresar el correo y la contraseña.
3. Tocar "Iniciar sesión".
4. Si las credenciales son válidas, se redirige al catálogo.

**Posibles mensajes:**

- "Credenciales incorrectas".
- "Cuenta bloqueada temporalmente. Intente de nuevo en X minutos".

#### 3.1.3. Recuperación de Contraseña

1. En la pantalla de inicio de sesión, tocar "¿Olvidaste tu contraseña?".
2. Ingresar el correo registrado.
3. Tocar "Enviar enlace".
4. El sistema envía un correo con el enlace de recuperación.
5. Abrir el correo y tocar el enlace.
6. Ingresar la nueva contraseña y confirmarla.
7. Tocar "Restablecer contraseña".
8. Volver a la app e iniciar sesión con la nueva contraseña.

**Nota:** Por seguridad, la app siempre devuelve el mismo mensaje ("Si el correo existe, recibirás un enlace") independientemente de si el correo está registrado o no (ver 05#D-04).

---

### 3.2. Explorar el Catálogo

#### 3.2.1. Navegar por el Catálogo

1. Al iniciar sesión, se muestra la pantalla principal con el catálogo.
2. Desplazarse verticalmente para ver más productos.
3. Usar los chips de categorías para filtrar.
4. Usar el botón "Filtros" para aplicar filtros avanzados:
   - Rango de precio (mínimo y máximo).
   - Disponibilidad.
   - Ordenamiento (relevancia, precio ascendente o descendente, nombre A-Z o Z-A).
5. Tocar un producto para ver su detalle.

#### 3.2.2. Buscar un Producto

1. Tocar la barra de búsqueda.
2. Escribir el nombre del producto.
3. Los resultados se actualizan automáticamente con un retardo de 300 ms.
4. Tocar un resultado para ver el detalle.

**Historial de búsquedas:** las últimas búsquedas se guardan localmente en el dispositivo. Se pueden reutilizar tocando cualquier entrada del historial, o borrar el historial completo desde el botón correspondiente (ver 05#D-13).

#### 3.2.3. Ver Detalle de un Producto

1. Tocar el producto en el catálogo o en los resultados de búsqueda.
2. Se muestra la pantalla de detalle con:
   - Imagen grande.
   - Nombre y precio.
   - Descripción.
   - Opciones personalizables.
   - Campo de observaciones.
   - Selector de cantidad.
3. Seleccionar opciones si aplica.
4. Ajustar la cantidad.
5. Escribir observaciones si es necesario.
6. Tocar "Agregar al carrito".
7. Aparece una confirmación (snackbar).

---

### 3.3. Gestionar el Carrito

#### 3.3.1. Ver el Carrito

1. Tocar el icono del carrito en la barra inferior.
2. Se muestra la lista de items con:
   - Imagen, nombre y opciones.
   - Cantidad editable.
   - Subtotal por item.
   - Botón de eliminar.
3. En la parte inferior se muestra el resumen: subtotal, envío y total.

#### 3.3.2. Modificar Cantidad o Eliminar un Item

1. Usar los botones "+" y "-" para ajustar la cantidad.
2. Si la cantidad llega a cero, el item se elimina automáticamente.
3. Para eliminar un item directamente, tocar el icono de papelera y confirmar.

#### 3.3.3. Vaciar el Carrito

1. En la parte superior del carrito, tocar el menú de opciones.
2. Seleccionar "Vaciar carrito".
3. Confirmar la acción.

---

### 3.4. Realizar un Pedido

1. Desde el carrito, tocar "Proceder al pago".
2. En la pantalla de checkout:
   - **Dirección de entrega:** seleccionar una dirección guardada o agregar una nueva.
   - **Método de pago:** elegir entre "Efectivo contra entrega" o "Tarjeta (simulado)".
   - **Resumen del pedido:** verificar items, subtotal, envío y total.
   - **Observaciones:** agregar notas si es necesario.
3. Tocar "Confirmar pedido".
4. El sistema valida stock, genera un número único y muestra la pantalla de confirmación.
5. Desde la confirmación, tocar "Seguir pedido" para ver el estado en tiempo real.

**Posibles mensajes:**

- "Stock insuficiente para uno o más productos".
- "El carrito está vacío".

**Nota:** Los métodos de pago son simulados (ver 05#D-08). No se solicitan datos de tarjeta ni se procesan transacciones reales.

---

### 3.5. Seguimiento del Pedido

1. Al confirmar un pedido, se abre automáticamente la pantalla de seguimiento.
2. Se muestra:
   - Número de pedido.
   - Estado actual (chip de color).
   - Línea de tiempo con los estados: pendiente, confirmado, preparando, listo, en camino, entregado.
   - Timestamps de cada cambio.
   - Detalles del pedido y dirección.
   - Tiempo estimado de entrega.
3. La pantalla se actualiza automáticamente cada 10 segundos (ver 05#D-01).
4. Si el pedido está en estado "pendiente" o "confirmado", aparece el botón "Cancelar pedido".

**Cancelar un pedido:**

1. Tocar "Cancelar pedido".
2. Ingresar un motivo opcional.
3. Confirmar la cancelación.
4. El stock se restaura automáticamente.

**Nota:** No se usan notificaciones push. La actualización es por polling.

---

### 3.6. Historial de Pedidos

1. Tocar el icono de historial en la barra inferior.
2. Se muestra la lista de pedidos ordenados por fecha descendente.
3. Usar los filtros por estado para refinar la lista.
4. Tocar un pedido para ver su detalle completo:
   - Número, fecha y estado final.
   - Items con cantidades y precios.
   - Total.
   - Dirección usada.
   - Historial de estados.
5. Desde el detalle, tocar "Reordenar" para agregar los productos de ese pedido al carrito actual.

**Reordenar:** los productos se agregan al carrito actual. Si algún producto ya no está disponible, se omite y se informa al usuario.

---

### 3.7. Perfil y Ajustes

#### 3.7.1. Editar Perfil

1. En el perfil, tocar "Editar perfil".
2. Modificar nombre, teléfono o avatar.
3. Guardar los cambios.

#### 3.7.2. Seguridad

1. En el perfil, tocar "Seguridad".
2. **Cambiar contraseña:** ingresar la contraseña actual, la nueva y confirmarla.
3. **Sesiones activas:** ver las sesiones abiertas con información de IP y dispositivo; revocar sesiones específicas.

#### 3.7.3. Direcciones

1. En el perfil, tocar "Mis direcciones".
2. Ver la lista de direcciones guardadas.
3. Agregar, editar, eliminar o marcar una dirección como predeterminada.

#### 3.7.4. Notificaciones

1. En el perfil, tocar "Notificaciones".
2. Ver el historial de notificaciones in-app.
3. Marcar notificaciones como leídas.
4. Configurar preferencias de notificaciones desde "Preferencias de notificaciones":
   - Tipos de notificación.
   - Sonido.
   - Vibración.
   - Frecuencia de actualización (10 segundos, 30 segundos o 1 minuto).

#### 3.7.5. Apariencia

1. En el perfil, tocar "Apariencia".
2. Configurar:
   - Tema (claro, oscuro o sistema).
   - Tamaño de texto (pequeño, normal, grande, muy grande).
   - Contraste.
   - Reducción de animaciones.
   - Modo daltónico.

#### 3.7.6. Idioma y Región

1. En el perfil, tocar "Idioma y región".
2. Configurar formato de fecha, hora y moneda.

#### 3.7.7. Privacidad

1. En el perfil, tocar "Privacidad".
2. Acceder a la política de privacidad, términos de uso y permisos de la app.

#### 3.7.8. Ayuda y Soporte

1. En el perfil, tocar "Ayuda y soporte".
2. Acceder a preguntas frecuentes, contactar soporte o reportar un problema.

#### 3.7.9. Acerca de

1. En el perfil, tocar "Acerca de".
2. Ver la versión, créditos y licencias.

#### 3.7.10. Avanzado

1. En el perfil, tocar "Avanzado".
2. Ejecutar acciones locales:
   - Limpiar caché de imágenes.
   - Limpiar datos locales.
   - Limpiar historial de búsquedas.
   - Restablecer preferencias.
   - Exportar datos personales.
   - Exportar historial de pedidos.

#### 3.7.11. Eliminar Cuenta

1. En el perfil, tocar "Cuenta".
2. Seguir las instrucciones para solicitar la eliminación.
3. La solicitud se procesa de forma manual por el equipo.

#### 3.7.12. Cerrar Sesión

1. En el perfil, desplazarse al final.
2. Tocar "Cerrar sesión".
3. Confirmar.

---

### 3.8. Centro de Notificaciones

1. Tocar el icono de campana en la barra superior.
2. Ver la lista de notificaciones.
3. Filtrar por tipo o no leídas.
4. Tocar una notificación para marcarla como leída y, si aplica, navegar al pedido relacionado.

---

## 4. Manual del Administrador

### 4.1. Acceso al Panel

1. Abrir el navegador e ingresar a la URL del panel.
2. Ingresar email y contraseña.
3. Tocar "Iniciar sesión".
4. Se redirige al dashboard.

---

### 4.2. Dashboard

1. Al ingresar, se muestra el dashboard con:
   - Tarjetas de métricas (pedidos hoy, ingresos hoy, pedidos activos, repartidores disponibles).
   - Gráfico de ventas de los últimos 7 días.
   - Últimos pedidos.
   - Accesos rápidos.
2. Los datos se actualizan automáticamente cada 30 segundos (ver 05#D-01).

---

### 4.3. Gestión de Pedidos

#### 4.3.1. Ver Lista de Pedidos

1. En el menú lateral, tocar "Pedidos".
2. Se muestra la tabla con todos los pedidos.
3. Usar filtros por estado, fecha, cliente o repartidor.
4. Usar la búsqueda por número o cliente.
5. La lista se actualiza automáticamente cada 30 segundos.

#### 4.3.2. Cambiar el Estado de un Pedido

1. Abrir el detalle del pedido.
2. En la sección de estado, seleccionar el nuevo estado.
3. Agregar un comentario opcional.
4. Guardar los cambios.

**Transiciones válidas:**

- Pendiente → Confirmado o Cancelado.
- Confirmado → Preparando o Cancelado.
- Preparando → Listo o Cancelado.
- Listo → En camino o Cancelado.
- En camino → Entregado.

#### 4.3.3. Asignar un Repartidor

1. Abrir el detalle de un pedido en estado "listo".
2. Tocar "Asignar repartidor".
3. Seleccionar un repartidor de la lista de disponibles.
4. Tocar "Asignar".

#### 4.3.4. Cancelar un Pedido

1. Abrir el detalle del pedido.
2. Tocar "Cancelar pedido".
3. Ingresar el motivo obligatorio.
4. Confirmar la acción.

#### 4.3.5. Exportar Pedidos

1. En la lista de pedidos, tocar "Exportar".
2. Elegir CSV o Excel.
3. El archivo se descarga con los pedidos filtrados.

---

### 4.4. Gestión de Productos

#### 4.4.1. Ver Lista de Productos

1. En el menú lateral, tocar "Productos".
2. Se muestra la tabla con todos los productos.
3. Usar filtros por nombre, categoría o disponibilidad.

#### 4.4.2. Crear un Producto

1. Tocar "+ Nuevo producto".
2. Completar el formulario:
   - Nombre, descripción, precio, categoría.
   - Imagen (subida a Cloudinary).
   - Stock inicial y stock mínimo.
   - Disponibilidad.
   - Opciones personalizables.
3. Tocar "Guardar producto".

#### 4.4.3. Editar un Producto

1. En la lista, tocar el icono de edición.
2. Modificar los campos deseados.
3. Si se modifica el precio, se registra automáticamente en el historial de precios.
4. Guardar los cambios.

#### 4.4.4. Activar o Desactivar Disponibilidad

1. En la lista, usar el toggle de disponibilidad.
2. Al desactivarlo, el producto se oculta del catálogo de clientes.

#### 4.4.5. Ajustar Stock

1. En la lista, tocar el icono de ajuste de stock.
2. Ingresar el nuevo stock y un motivo opcional.
3. Guardar.

#### 4.4.6. Eliminar un Producto

1. En la lista, tocar el icono de papelera.
2. Confirmar la acción.
3. El producto se marca como no disponible (eliminación lógica).

#### 4.4.7. Gestionar Opciones de Producto

1. Editar un producto.
2. En la sección de opciones, agregar, editar o desactivar opciones.
3. Guardar.

#### 4.4.8. Historial de Precios

1. En la lista, tocar el icono de historial de precios.
2. Ver los cambios registrados con usuario, motivo y fecha.

---

### 4.5. Gestión de Categorías

1. En el menú lateral, tocar "Categorías".
2. Ver, crear, editar o desactivar categorías.

---

### 4.6. Gestión de Repartidores

#### 4.6.1. Ver Lista de Repartidores

1. En el menú lateral, tocar "Repartidores".
2. Se muestra la tabla con estado, vehículo y entregas completadas.
3. Usar filtros por estado.

#### 4.6.2. Dar de Alta un Repartidor

1. Tocar "+ Nuevo repartidor".
2. Seleccionar un usuario con rol "repartidor".
3. Ingresar el vehículo (opcional).
4. Guardar.

#### 4.6.3. Editar un Repartidor

1. Tocar el icono de edición.
2. Modificar vehículo o estado.
3. Guardar.

**Nota:** No se puede marcar como "disponible" si el repartidor tiene pedidos activos.

#### 4.6.4. Desactivar un Repartidor

1. Tocar el icono de desactivación.
2. Confirmar.

#### 4.6.5. Ver Historial

1. Tocar el nombre del repartidor.
2. Ver su historial de entregas y métricas.

---

### 4.7. Reportes

1. En el menú lateral, tocar "Reportes".
2. Elegir el tipo de reporte:
   - Ventas por día.
   - Productos más vendidos.
   - Clientes frecuentes.
   - Rendimiento de repartidores.
3. Ajustar el rango de fechas si aplica.
4. Tocar "Exportar" para descargar en CSV o Excel.

**Nota:** No hay exportación a PDF en v1.0.

---

### 4.8. Configuración

1. En el menú lateral, tocar "Configuración".
2. Ver y editar parámetros globales:
   - Costo de envío por defecto.
   - Tiempo estimado de preparación.
   - Tiempo estimado de entrega.
   - Horas de expiración del carrito.
   - Máximo de intentos de login.
3. Guardar los cambios.

---

### 4.9. Auditoría

1. En el menú lateral, tocar "Auditoría".
2. Ver el registro de acciones críticas.
3. Filtrar por usuario, entidad o rango de fechas.
4. Expandir una fila para ver el detalle en formato JSON.

---

### 4.10. Perfil del Administrador

1. En el menú lateral, tocar "Perfil".
2. Editar datos personales, cambiar contraseña o cerrar sesión.
3. Consultar las sesiones activas.

---

## 5. Manual del Repartidor

### 5.1. Primer Acceso

1. Abrir la aplicación QuickBite.
2. Ingresar email y contraseña proporcionados por el administrador.
3. Tocar "Iniciar sesión".
4. Se redirige a la pantalla de pedidos disponibles.

---

### 5.2. Pedidos Disponibles

1. En la pestaña "Disponibles", se muestra la lista de pedidos en estado "listo".
2. Cada tarjeta muestra:
   - Número de pedido.
   - Dirección resumida.
   - Total.
   - Tiempo desde que está listo.
3. La lista se actualiza automáticamente cada 30 segundos (ver 05#D-01).
4. Para actualizar manualmente, deslizar hacia abajo (pull-to-refresh).

**Si no hay pedidos disponibles:** se muestra un mensaje informativo.

---

### 5.3. Aceptar un Pedido

1. Tocar un pedido de la lista.
2. Se muestra el detalle completo.
3. Tocar "Aceptar entrega".
4. Confirmar en el diálogo.
5. El pedido pasa a estado "en camino" y el repartidor queda ocupado.
6. Se redirige a "Entrega activa".

---

### 5.4. Gestionar la Entrega Activa

1. En la pestaña "Entrega activa", se muestra el pedido actual.
2. Se incluye:
   - Dirección completa con referencia.
   - Botón "Llamar al cliente".
   - Lista de productos y observaciones.
   - Total.
3. Realizar la entrega física.

**Nota:** No hay integración con mapas en v1.0. Se muestra solo la dirección textual con referencia.

---

### 5.5. Marcar como Entregado

1. En la pantalla de entrega activa, tocar "Marcar como entregado".
2. Confirmar.
3. El pedido pasa a estado "entregado".
4. El repartidor vuelve al estado "disponible".
5. Se redirige a "Disponibles".

---

### 5.6. Historial de Entregas

1. En la pestaña "Historial", se muestra la lista de entregas completadas.
2. Filtrar por fecha si es necesario.
3. Tocar una entrega para ver el detalle.

---

### 5.7. Estadísticas Personales

1. En el perfil, tocar "Estadísticas".
2. Ver:
   - Entregas totales.
   - Entregas del mes actual.
   - Tiempo promedio de entrega.
   - Pedidos asignados.
   - Cancelaciones.

---

### 5.8. Perfil y Ajustes

El repartidor tiene acceso a las mismas opciones de perfil y ajustes que el cliente, con las siguientes diferencias:

| Opción | Cliente | Repartidor |
| :--- | :--- | :--- |
| Direcciones | Sí | No |
| Estadísticas | No | Sí |
| Disponibilidad | No | Sí (toggle disponible / ocupado / inactivo) |
| Resto de opciones | Igual | Igual |

---

### 5.9. Cerrar Sesión

1. En el perfil, tocar "Cerrar sesión".
2. Confirmar.

---

## 6. Preguntas Frecuentes

### 6.1. Cliente

**¿Cómo puedo rastrear mi pedido?**
Al confirmar el pedido, se abre la pantalla de seguimiento. La pantalla se actualiza automáticamente cada 10 segundos (polling). También se puede acceder desde el historial.

**¿Recibiré notificaciones push?**
No. La app no usa notificaciones push. La información se actualiza por polling.

**¿Puedo cancelar un pedido?**
Sí, si el pedido está en estado "pendiente" o "confirmado". Una vez que entra en preparación, no se puede cancelar desde la app.

**¿Qué métodos de pago aceptan?**
Efectivo contra entrega y tarjeta (simulado). No se procesan transacciones reales.

**¿Puedo reordenar un pedido anterior?**
Sí. Desde el detalle de un pedido histórico, tocar "Reordenar" para agregar los productos al carrito actual.

**¿Se guardan mis búsquedas?**
Sí, las últimas búsquedas se guardan localmente en el dispositivo. Se pueden borrar desde "Avanzado".

**¿Puedo cambiar el tema de la app?**
Sí, desde "Apariencia" en el perfil.

**¿Puedo ver y cerrar sesiones abiertas en otros dispositivos?**
Sí, desde "Seguridad" → "Sesiones activas".

### 6.2. Administrador

**¿Cómo asigno un repartidor a un pedido?**
Abrir el detalle del pedido en estado "listo" y tocar "Asignar repartidor".

**¿Puedo modificar el precio de un producto?**
Sí. Al editarlo, el sistema registra el cambio en el historial de precios.

**¿Cómo exporto un reporte?**
En la sección de reportes, seleccionar el tipo y tocar "Exportar".

**¿Qué pasa si un producto se queda sin stock?**
El sistema muestra una alerta cuando el stock cae por debajo del mínimo. Se puede ajustar el stock o desactivar la disponibilidad.

**¿El panel se actualiza automáticamente?**
Sí. El dashboard y la lista de pedidos se actualizan automáticamente cada 30 segundos.

**¿Puedo gestionar usuarios (crear, editar, cambiar roles)?**
No. La gestión de usuarios está fuera del alcance de v1.0.

**¿Puedo gestionar varias sucursales?**
No. QuickBite es un sistema mono-sucursal.

### 6.3. Repartidor

**¿Cómo sé si hay nuevos pedidos disponibles?**
La lista se actualiza automáticamente cada 30 segundos.

**¿Puedo aceptar más de un pedido a la vez?**
No. Al aceptar un pedido, quedas marcado como ocupado hasta que lo entregues.

**¿Qué hago si no encuentro la dirección?**
Usar el botón "Llamar al cliente" para solicitar indicaciones.

**¿Dónde veo mis estadísticas?**
En el perfil, tocar "Estadísticas".

**¿Puedo cambiar mi disponibilidad?**
Sí, desde "Disponibilidad" en el perfil.

---

## 7. Soporte

| Perfil | Canal de soporte |
| :--- | :--- |
| Cliente | Contacto con el equipo de desarrollo durante la demostración |
| Administrador | Contacto con el equipo de desarrollo durante la demostración |
| Repartidor | Contacto con el equipo de desarrollo durante la demostración |

Al ser un proyecto con alcance cerrado, no hay canal de soporte formal.

---

## 8. Glosario

| Término | Definición |
| :--- | :--- |
| Catálogo | Lista de productos disponibles |
| Carrito | Espacio donde se acumulan productos antes de confirmar el pedido |
| Checkout | Proceso de confirmación del pedido |
| Estado del pedido | Fase actual del pedido (pendiente, confirmado, preparando, listo, en camino, entregado, cancelado) |
| Repartidor | Persona encargada de entregar el pedido |
| Stock | Cantidad disponible de un producto |
| Polling | Consulta periódica al servidor para actualizar el estado |
| Sesión activa | Token de refresco no revocado y no expirado |
| Reordenar | Agregar los productos de un pedido anterior al carrito actual |
| Timeline | Línea de tiempo de estados |

---

## 9. Referencias a Decisiones Canónicas

| Decisión | Impacto en el manual | Referencia |
| :--- | :--- | :--- |
| Polling | Actualización automática sin notificaciones push | 05#D-01 |
| Pagos simulados | No se solicitan datos de tarjeta | 05#D-08 |
| Modelo mono-sucursal | Sin selector de sucursal | 05#D-09 |
| APK firmado | Instalación manual del APK | 05#D-07 |
| Historial de búsquedas local | Búsquedas guardadas por dispositivo | 05#D-13 |

---

## 10. Referencias a Otros Documentos

| Documento | Contenido referenciado |
| :--- | :--- |
| 05 | Decisiones canónicas |
| 07.1 | Especificación detallada de pantallas móviles |
| 08.1 | Especificación detallada de páginas del panel admin |
| 09 | Sistema de diseño |
| 11 | Preparación para la demostración |

---

**Fin del Documento 13.**