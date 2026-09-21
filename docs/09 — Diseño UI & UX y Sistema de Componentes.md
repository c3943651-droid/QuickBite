**Versión:** 3.0
**Fecha:** 14/09/2026
**Estado:** Aprobado
**Audiencia:** Diseño, React Native, Blazor
**Depende de:** 00, 05
**Referenciado por:** 07, 07.1, 08, 08.1, 12, 13

---

## 1. Introducción

Este documento define el sistema de diseño de QuickBite: la identidad visual, los principios de experiencia de usuario, la paleta de colores, la tipografía, el sistema de espaciado, y el catálogo de componentes reutilizables que se aplican tanto en la app móvil (React Native) como en el panel de administración (Blazor).

La arquitectura de la app móvil reside en el documento 07 y la especificación de sus pantallas en el documento 07.1. La arquitectura del panel admin reside en el documento 08 y la especificación de sus páginas en el documento 08.1. Este documento no repite pantallas ni páginas: se enfoca en las reglas de diseño que ambos comparten.

Las decisiones canónicas que afectan al diseño (polling, pagos simulados, modo mono-sucursal, historial de búsquedas local) residen en el documento 05.

---

## 2. Principios de Diseño UX

| Principio | Descripción |
| :--- | :--- |
| Rapidez ante todo | Cada pantalla tiene un objetivo claro y un único llamado a la acción principal |
| Claridad visual | La información crítica (precio, estado, tiempo estimado) es visible sin esfuerzo |
| Feedback constante | Cada acción del usuario recibe una respuesta inmediata |
| Consistencia | Los mismos patrones de interacción se repiten en la app y en el panel |
| Accesibilidad | Contraste, tamaño táctil y etiquetas semánticas cumplen estándares |
| Confianza | Transparencia en precios, estados y tiempos |
| Calidez | La paleta y la tipografía transmiten cercanía, no frialdad corporativa |
| Coherencia multiplataforma | App móvil y panel web comparten identidad visual, adaptada a cada plataforma |

---

## 3. Identidad Visual

### 3.1. Concepto de Marca

QuickBite se posiciona como una solución moderna, rápida y cercana para restaurantes de comida rápida. Su identidad evoca:

- **Energía y dinamismo:** colores cálidos y formas redondeadas.
- **Confianza y limpieza:** espacios blancos y tipografía clara.
- **Apetito:** tonos anaranjados y rojizos.

### 3.2. Logotipo

| Aspecto | Definición |
| :--- | :--- |
| Símbolo | Letra "Q" estilizada que integra silueta de tenedor y un rayo |
| Logotipo completo | Símbolo + palabra "QuickBite" |
| Tipografía del logotipo | Sans-serif redondeada |
| Versiones | Horizontal, vertical y monocromática |
| Área de respeto | Espacio mínimo equivalente a la altura de la letra "Q" |

---

## 4. Paleta de Colores

### 4.1. Colores de Marca

| Nombre | Código | Uso principal |
| :--- | :--- | :--- |
| Naranja QuickBite | `#FF6B35` | Color principal: botones primarios, encabezados, acentos |
| Rojo Apetito | `#D62828` | Color secundario: badges de notificación, alertas, descuentos |
| Amarillo Energía | `#F7B801` | Color terciario: destacados, promociones, calificaciones |

### 4.2. Colores Neutros

| Nombre | Código | Uso principal |
| :--- | :--- | :--- |
| Blanco Puro | `#FFFFFF` | Fondos principales y tarjetas |
| Gris Niebla | `#F5F5F5` | Fondos secundarios y separadores |
| Gris Texto | `#4A4A4A` | Texto principal sobre fondos claros |
| Gris Secundario | `#9E9E9E` | Texto secundario y placeholders |
| Negro Suave | `#1A1A1A` | Texto de alto contraste y modo oscuro |

### 4.3. Colores Semánticos

| Nombre | Código | Uso principal |
| :--- | :--- | :--- |
| Verde Éxito | `#2E7D32` | Confirmaciones, pedido entregado, stock disponible |
| Rojo Error | `#C62828` | Errores, cancelaciones, stock agotado |
| Amarillo Advertencia | `#F9A825` | Advertencias, pedido en preparación, stock bajo |
| Azul Información | `#1565C0` | Mensajes informativos, enlaces, pedido en camino |

### 4.4. Reglas de Uso

- El naranja QuickBite se reserva para acciones principales. **Un solo botón primario por pantalla.**
- El rojo se usa con moderación, solo en elementos críticos.
- Los colores semánticos nunca se usan como decoración: siempre comunican un estado.
- El contraste de texto sobre fondo cumple WCAG 2.1 AA en todos los casos.

### 4.5. Modo Oscuro

El modo oscuro es una opción disponible en la app y en el panel, activable desde la pantalla de apariencia (ver 07.1 y 08.1). La paleta alternativa es:

| Elemento | Código |
| :--- | :--- |
| Fondo principal | `#121212` |
| Superficie de tarjetas | `#1E1E1E` |
| Texto principal | `#E0E0E0` |
| Texto secundario | `#9E9E9E` |
| Colores de marca | Se mantienen, con ajuste de brillo para mantener contraste |

---

## 5. Tipografía

### 5.1. Fuente

| Aspecto | Definición |
| :--- | :--- |
| Fuente principal | Roboto o Inter |
| Justificación | Amplia disponibilidad, excelente legibilidad, múltiples pesos |
| Aplicación en React Native | Fuente de Google Fonts o la fuente por defecto del sistema |
| Aplicación en Blazor | Configuración en el tema de MudBlazor |

### 5.2. Escala Tipográfica

| Estilo | Tamaño | Peso | Uso |
| :--- | :--- | :--- | :--- |
| Display | 32 | Bold (700) | Títulos grandes, números destacados |
| Headline 1 | 24 | Bold (700) | Títulos de pantalla principal |
| Headline 2 | 20 | SemiBold (600) | Subtítulos de sección |
| Title | 18 | SemiBold (600) | Títulos de tarjetas y nombres de producto |
| Body Large | 16 | Regular (400) | Texto principal, descripciones |
| Body Medium | 14 | Regular (400) | Texto secundario, etiquetas |
| Label | 12 | Medium (500) | Botones, etiquetas de formulario, badges |
| Caption | 10 | Regular (400) | Notas al pie, textos auxiliares |

### 5.3. Reglas de Uso

- **Interlineado:** 1.5x el tamaño de fuente para textos largos; 1.2x para títulos.
- **Alineación:** izquierda por defecto; centrado solo en pantallas de bienvenida y modales de confirmación.
- **Jerarquía:** nunca más de 3 niveles tipográficos en una misma pantalla.
- **Contraste:** texto sobre fondos claros usa Gris Texto o Negro Suave; sobre fondos oscuros usa Blanco Puro o Gris Texto claro.

---

## 6. Sistema de Espaciado

El espaciado se basa en una grilla de 8 puntos.

| Token | Valor | Uso |
| :--- | :--- | :--- |
| space-xs | 4 px | Separación entre icono y texto |
| space-sm | 8 px | Espaciado interno de componentes pequeños |
| space-md | 16 px | Margen estándar entre elementos |
| space-lg | 24 px | Separación entre secciones |
| space-xl | 32 px | Márgenes de pantalla y separación entre bloques grandes |
| space-xxl | 48 px | Espaciado en pantallas de bienvenida o vacías |

---

## 7. Grillas y Bordes

### 7.1. Grillas

| Contexto | Columnas | Margen lateral | Gutter |
| :--- | :--- | :--- | :--- |
| Móvil (React Native) | 4 | 16 px | 16 px |
| Tablet (React Native) | 8 | 24 px | 16 px |
| Web (Blazor admin) | 12 | 24 px, máximo 1280 px centrado | 24 px |

### 7.2. Bordes Redondeados

| Componente | Radio |
| :--- | :--- |
| Botones | 12 px |
| Tarjetas | 16 px |
| Campos de texto | 8 px |
| Imágenes de producto | 12 px |
| Modales y diálogos | 24 px |
| Chips y etiquetas | 20 px (forma de píldora) |

### 7.3. Elevación

| Nivel | Uso |
| :--- | :--- |
| 0 | Fondos, superficies planas |
| 1 | Tarjetas de producto, items de lista |
| 2 | Barra superior al hacer scroll, botones flotantes |
| 3 | Modales, bottom sheets |
| 4 | Diálogos de confirmación |
| 5 | Notificaciones emergentes (snackbars elevados) |

---

## 8. Catálogo de Componentes

Los componentes se describen por su comportamiento y aspecto. Los componentes nativos se implementan con los componentes base de React Native o con MudBlazor, según la plataforma.

### 8.1. Botones

| Tipo | Apariencia | Uso |
| :--- | :--- | :--- |
| Primario | Fondo naranja, texto blanco, bordes redondeados, altura 48 px | Acción principal de la pantalla |
| Secundario | Fondo transparente, borde naranja 2 px, texto naranja | Acciones alternativas |
| Terciario | Sin fondo ni borde, texto naranja | Acciones menores |
| Peligro | Fondo rojo, texto blanco | Acciones destructivas |
| Deshabilitado | Fondo gris claro, texto gris | Acción no disponible |

**Estados:** normal, presionado, cargando (spinner), deshabilitado.

### 8.2. Campos de Texto

| Aspecto | Definición |
| :--- | :--- |
| Altura | 56 px |
| Borde | Redondeado 8 px; al enfocar, borde naranja 2 px |
| Etiqueta flotante | Se mueve hacia arriba al enfocar o con contenido |
| Iconos | Opcionales a la izquierda o derecha |
| Validación | Mensaje de error en rojo debajo del campo con icono |
| Tipos | Texto, email, contraseña, teléfono, numérico, búsqueda, multilínea |

### 8.3. Tarjetas

| Tipo | Contenido |
| :--- | :--- |
| Tarjeta de producto | Imagen, nombre, descripción corta, precio, botón de agregar |
| Tarjeta de pedido | Número, estado (chip), total, fecha, dirección resumida |
| Tarjeta de repartidor | Nombre, estado (badge), entregas completadas, botón de historial |
| Tarjeta de métrica | Título, valor destacado, icono |

Elevación nivel 1, esquinas redondeadas 16 px.

### 8.4. Chips y Etiquetas

| Tipo | Apariencia |
| :--- | :--- |
| Chip de estado | Fondo del color semántico con opacidad 20 %, texto del color semántico |
| Chip de categoría | Fondo gris claro; cuando está activo, fondo naranja |
| Badge de notificación | Círculo rojo con número blanco |
| Badge de estado | Píldora con texto y color según estado |

### 8.5. Indicadores de Carga

| Tipo | Uso |
| :--- | :--- |
| Spinner circular | Operaciones puntuales (login, guardar) |
| Skeleton | Carga de listas y tarjetas |
| Barra de progreso lineal | Operaciones con progreso medible |

### 8.6. Vistas de Estado

| Estado | Apariencia |
| :--- | :--- |
| Vacío | Ilustración amigable, mensaje motivador, botón de acción |
| Error | Icono de advertencia, mensaje claro, botón de reintentar |
| Sin conexión | Icono de nube desconectada, mensaje, botón de reintentar |
| Cargando (polling) | Indicador sutil de "Actualizando..." sin bloquear la interacción |

### 8.7. Diálogos y Modales

| Tipo | Uso |
| :--- | :--- |
| Bottom sheet | Opciones contextuales, filtros rápidos |
| Dialog | Confirmaciones críticas |
| Snackbar | Feedback breve no intrusivo |

**Regla:** Toda acción destructiva requiere confirmación mediante diálogo.

### 8.8. Barra de Navegación Inferior (React Native)

| Rol | Pestañas |
| :--- | :--- |
| Cliente | Catálogo, Carrito, Historial, Perfil |
| Repartidor | Disponibles, Entrega activa, Historial |

**Estilo:** iconos outlined cuando no están activos; iconos filled cuando están activos. Color activo naranja. Indicador de píldora detrás del icono activo.

### 8.9. Barra Superior

| Aspecto | Definición |
| :--- | :--- |
| Título | Centrado o alineado a la izquierda según la pantalla |
| Acciones | Iconos de notificaciones, carrito (si aplica), menú de perfil |
| Elevación | 0 en reposo; nivel 2 al hacer scroll |
| Color | Fondo blanco con texto oscuro; fondo naranja con texto blanco en pantallas de bienvenida |

### 8.10. Menú Lateral (Blazor)

| Aspecto | Definición |
| :--- | :--- |
| Posición | Lateral izquierdo |
| Estado | Expandido o colapsado |
| Secciones | Dashboard, Pedidos, Productos, Categorías, Repartidores, Reportes, Configuración, Auditoría |
| Iconos | Uno por sección |

### 8.11. Tablas (Blazor)

| Aspecto | Definición |
| :--- | :--- |
| Uso | Listados de pedidos, productos, repartidores, auditoría |
| Paginación | Server-side |
| Ordenamiento | Por cualquier columna visible |
| Filtros | Chips o campos en la parte superior |
| Acciones por fila | Botones de icono (editar, eliminar, ver detalle) |
| Responsive | En pantallas pequeñas, las tablas se convierten en tarjetas apiladas |

### 8.12. Timeline

| Aspecto | Definición |
| :--- | :--- |
| Uso | Estados secuenciales de un pedido |
| Representación | Vertical con iconos, timestamps y check por paso completado |
| Paso actual | Indicador animado (pulso) |
| Pasos futuros | Iconos atenuados |

### 8.13. Indicador de Polling

| Aspecto | Definición |
| :--- | :--- |
| Aparición | Texto "Actualizando..." en la parte superior de la pantalla |
| Duración | Solo mientras se consulta la API |
| Bloqueo | No bloquea la interacción |
| Estilo | Texto pequeño con icono sutil |

---

## 9. Estados Transversales

Los siguientes estados aparecen en múltiples pantallas y siguen las mismas reglas.

### 9.1. Estado Vacío

| Aspecto | Definición |
| :--- | :--- |
| Ilustración | Amigable, alineada con la marca |
| Mensaje | Claro y motivador |
| Acción | Botón que sugiere el siguiente paso |
| Posición | Centrado verticalmente |

### 9.2. Estado de Carga

| Aspecto | Definición |
| :--- | :--- |
| Tipo | Skeleton con la forma del contenido esperado |
| Excepción | Para operaciones puntuales, spinner circular |
| Duración mínima | No aplica; se muestra solo si la operación supera 500 ms |

### 9.3. Estado de Error

| Aspecto | Definición |
| :--- | :--- |
| Ilustración | Icono de advertencia o error |
| Mensaje | Claro, sin tecnicismos |
| Acción | Botón "Reintentar" |
| Registro | Se registra en logs locales sin exponer detalles técnicos al usuario |

### 9.4. Estado Sin Conexión

| Aspecto | Definición |
| :--- | :--- |
| Detección | Automática al perder conectividad |
| Comportamiento | Se muestra overlay o se bloquea la acción puntual |
| Acción | Botón "Reintentar" |
| Reintento | Automático con backoff en segundo plano |

---

## 10. Microinteracciones y Animaciones

| Elemento | Animación | Duración |
| :--- | :--- | :--- |
| Transición entre pantallas | Slide horizontal | 300 ms |
| Apertura de bottom sheet | Slide vertical desde abajo | 250 ms |
| Aparición de snackbar | Slide desde abajo + fade | 200 ms |
| Cambio de estado en timeline | Pulso + cambio de color | 500 ms |
| Agregar al carrito | Scale del icono + badge | 300 ms |
| Carga de imágenes | Fade in con placeholder | 200 ms |
| Pull-to-refresh | Animación circular estándar | Variable |
| Indicador de polling | Fade in/out sutil | 200 ms |

**Principio:** las animaciones son sutiles y rápidas (menos de 300 ms) para no obstaculizar la fluidez. Nunca bloquean la interacción.

---

## 11. Accesibilidad

| Aspecto | Medida |
| :--- | :--- |
| Contraste | Cumple WCAG 2.1 AA (ratio mínimo 4.5:1 para texto normal, 3:1 para texto grande) |
| Tamaño de toque | Todos los elementos interactivos tienen al menos 48x48 px de área táctil |
| Etiquetas semánticas | Los widgets interactivos incluyen etiquetas para lectores de pantalla |
| Navegación por teclado | El panel web es navegable completamente con teclado (Tab, Enter, Esc) |
| Texto escalable | La app respeta la configuración de tamaño de fuente del sistema hasta 200 % |
| Alternativas visuales | Los estados no se comunican solo por color; también por iconos y texto |
| Reducción de movimiento | La opción de reducir animaciones está disponible en apariencia |

---

## 12. Responsive Design

### 12.1. App Móvil (React Native)

| Aspecto | Definición |
| :--- | :--- |
| Orientación | Optimizada para vertical; adaptable a horizontal |
| Grid | Dos columnas en móvil; tres columnas en tablet |
| Adaptación | Mediante consultas de medios y constructores de diseño |

### 12.2. Panel Web (Blazor)

| Breakpoint | Ancho | Diseño |
| :--- | :--- | :--- |
| Móvil | < 768 px | Menú hamburguesa, tablas colapsables, una columna |
| Tablet | 768 – 1024 px | Menú lateral colapsable, tablas con scroll, dos columnas |
| Escritorio | > 1024 px | Menú lateral fijo, tablas completas, múltiples columnas |

**Componentes adaptativos:** tablas que se convierten en tarjetas; menú lateral que se convierte en menú hamburguesa; gráficos que simplifican su visualización.

---

## 13. Temas

### 13.1. Tema Claro (por defecto)

- Fondo principal: blanco puro.
- Fondos secundarios: gris niebla.
- Texto: gris texto o negro suave.
- Colores de marca: naranja, rojo, amarillo.

### 13.2. Tema Oscuro

- Fondo principal: negro suave.
- Superficie de tarjetas: gris oscuro.
- Texto: blanco o gris claro.
- Colores de marca: se mantienen con ajuste de brillo.

### 13.3. Selección de Tema

El usuario puede elegir entre claro, oscuro o seguir el tema del sistema. La opción se guarda en preferencias locales (ver 07.1 y 08.1).

---

## 14. Aplicación por Plataforma

El sistema de diseño se aplica con adaptaciones específicas por plataforma.

| Elemento | App móvil (React Native) | Panel web (Blazor) |
| :--- | :--- | :--- |
| Navegación principal | Barra inferior | Menú lateral |
| Densidad de información | Media | Alta |
| Componentes principales | Sistema de diseño de QuickBite | Componentes MudBlazor |
| Tamaño de fuente base | 14–16 | 14–16 |
| Interacciones táctiles | Sí | Sí, con soporte de teclado |
| Estado del sistema | Barra de estado de Android | Título de pestaña del navegador |

---

## 15. Referencias a Decisiones Canónicas

| Decisión | Impacto en el diseño | Referencia |
| :--- | :--- | :--- |
| Polling | Indicador sutil de "Actualizando..." | 05#D-01 |
| Pagos simulados | No hay campos de tarjeta | 05#D-08 |
| Modelo mono-sucursal | Sin selector de sucursal | 05#D-09 |
| Cloudinary | Imágenes optimizadas y cacheadas | 05#D-06 |

---

## 16. Referencias a Otros Documentos

| Documento | Contenido referenciado |
| :--- | :--- |
| 05 | Decisiones canónicas |
| 07 | Arquitectura de la app móvil |
| 07.1 | Especificación de pantallas móviles |
| 08 | Arquitectura del panel admin |
| 08.1 | Especificación de páginas del panel admin |
| 12 | Pruebas de usabilidad y accesibilidad |
| 13 | Manual del usuario final |

---

## 17. Glosario

| Término | Definición |
| :--- | :--- |
| Sistema de diseño | Conjunto de reglas visuales y de interacción compartidas |
| Chip | Elemento seleccionable o etiqueta en forma de píldora |
| Skeleton | Placeholder animado con la forma del contenido |
| Snackbar | Notificación breve en la parte inferior |
| Bottom sheet | Panel que se desliza desde abajo |
| Elevación | Nivel de sombra que indica profundidad |
| Timeline | Representación visual de estados secuenciales |
| Breakpoint | Punto de quiebre para adaptar el diseño a distintos tamaños |
| Token de espaciado | Valor predefinido de espaciado basado en la grilla de 8 puntos |

---

**Fin del Documento 09.**