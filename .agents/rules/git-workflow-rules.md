# Reglas de Flujo Git para Agentes (`QuickBite`)

Este documento define las reglas de comportamiento que cualquier agente de IA o desarrollador humano debe seguir al interactuar con Git en este repositorio.

---

## 1. Política de Ramas

- **Ramas Principales:**
  - `main`: Código estable de producción.
  - `develop`: Rama de integración activa para el desarrollo continuo.
- **Ramas de Trabajo:**
  - Toda nueva funcionalidad debe partir de `develop` con el prefijo `feature/<nombre-descriptivo>`.
  - Toda corrección de errores debe usar el prefijo `fix/<nombre-descriptivo>`.
  - Cualquier trabajo de optimización puede usar `perf/<nombre>` o `feature/<nombre>`.
  - **Prohibido commitear directamente en `develop`, `main` o `master`.** Si el agente está
    en una rama protegida con cambios pendientes, debe crear la rama de trabajo antes de confirmar.
    El comando `git-auto.sh auto` hace esto automáticamente.

---

## 2. Formato de Mensajes de Commit (Conventional Commits)

Los mensajes de commit deben ser claros, en minúsculas y seguir el estándar Conventional Commits:

```
<tipo>(<ámbito opcional>): <descripción imperativa corta>

[cuerpo explicativo opcional detallando el porqué del cambio]
```

- **Ámbitos sugeridos (por capa/frente):** `api`, `application`, `domain`, `infra`, `admin`, `mobile`, `shared`, `docs`, `db`.
- **Tipos permitidos:**
  - `feat`: Nueva funcionalidad o capacidad pública.
  - `fix`: Corrección de un fallo o error en tests/comportamiento.
  - `chore`: Tareas de mantenimiento, actualización de configuración o limpieza.
  - `docs`: Modificación o adición de especificaciones o documentación.
  - `test`: Adición o refactorización de pruebas unitarias o de integración.
  - `perf`: Optimizaciones de rendimiento.

---

## 3. Higiene y Validación Previa

Antes de realizar un commit o enviar cambios al remoto:
1. Asegurar que `git status` no contenga archivos basura o artefactos no rastreados.
2. Ejecutar las comprobaciones obligatorias según el frente que se toque:
   - Backend `.NET`: `dotnet build backend/src/QuickBite.sln` y `dotnet test backend/tests/QuickBite.Tests.Unit/`.
   - Lint estricto del backend: `dotnet build backend/src/QuickBite.sln -warnaserror`.
   - Formato del backend: `dotnet format backend/src/QuickBite.sln --verify-no-changes`.
   - Móvil (React Native): `npm run lint` y `npm test` (desde `mobile/`).
   - Formato del móvil: `npx prettier --check .` (desde `mobile/`).

---

## 4. Política de Pull Requests

- Los Pull Requests de características se abren hacia la rama `develop`.
- El título del PR debe resumir la contribución con su prefijo semántico.
- El cuerpo debe describir los cambios realizados, las pruebas ejecutadas y el resultado de la verificación.

---

## 5. Envío automatizado (recomendado)

Para "enviar al repo" usa un solo comando que automatiza toda la cadena:

```bash
bash .agents/scripts/git-auto.sh auto          # auto-detecta tipo y ámbito
bash .agents/scripts/git-auto.sh auto fix      # fuerza tipo fix
```

`auto` (alias `send`) hace lo siguiente, en orden:

1. Si se está en `develop`/`main`/`master`, crea automáticamente una rama
   `feature/`, `fix/` o `chore/` con un slug descriptivo derivado de los cambios.
2. Hace `git add -A`.
3. Verifica el frente afectado (`dotnet build -warnaserror` en backend o `npm run lint` en móvil);
   si falla, aborta sin commitear. Se puede omitir con `GIT_AUTO_SKIP_VERIFY=1`.
4. Genera un mensaje de commit Conventional Commits automático
   (`feat(ámbito): add ...`, `fix(ámbito): fix ...`, `docs: update ...`) a partir del diff.
5. Hace commit y `git push -u origin <rama>`.
6. Abre o actualiza el Pull Request hacia `develop` con `gh`, **generando título y
   cuerpo automáticamente** desde el diff de la rama (lista de archivos + verificación).

Para ver qué hará sin tocar nada: `bash .agents/scripts/git-auto.sh preview`.
Para abrir/actualizar el PR de una rama ya publicada: `bash .agents/scripts/git-auto.sh pr develop`.
El comando `pr` se niega a abrir PR desde `develop`/`main`/`master` o sin commits propios frente a la base.