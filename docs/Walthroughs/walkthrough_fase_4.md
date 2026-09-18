# Walkthrough — Fase 4: Catálogo 🍔

Implementación mínima viable del catálogo público y admin.

## Componentes
- **Application/Catalog**: DTOs (`CategoryDtos`, `ProductDtos`), validadores FluentValidation, `ICatalogService`/`CatalogService` (CRUD categorías/productos, filtros paginados, opciones, disponibilidad, stock con historial de precios), `IImageService`.
- **Infrastructure/Images/CloudinaryImageService**: stub que devuelve URL `https://res.cloudinary.com/demo/{file}` (reemplazable por SDK real vía config `Cloudinary`).
- **Api/Controllers**: `CatalogController` (`GET /api/v1/categories`, `GET /api/v1/products` con `categoria_id/search/disponible/precio_min/precio_max/orden/page/limit`, `GET /api/v1/products/{id}`, `GET /api/v1/products/{id}/options`) público; `AdminCatalogController` (`POST/PUT/DELETE /api/v1/admin/categories`, `POST/PUT/DELETE /api/v1/admin/products`, `PATCH availability/stock`, `POST/PUT/DELETE options`) requiere `administrador`.

## Filtros
- `ProductFilterParams` delegado al repositorio (paginación, búsqueda ILIKE, rango precio, orden `relevancia/precio_asc/precio_desc/nombre_asc/nombre_desc`), validación `precio_min <= precio_max`.

## Verificación
- `dotnet build -warnaserror` 0/0
- `dotnet test` unit 87/87
- `dotnet format` limpio
