---
name: git-workflow
description: Automatiza branch, commit, push, PR y sincronización usando .agents/scripts/git-auto.sh y las reglas de git-workflow-rules.md
---

# Git Workflow Skill (`QuickBite`)

## Cuándo usar

Usa esta skill cuando el usuario o el flujo de trabajo requiera:
- Crear una nueva rama de características o corrección (`branch`).
- Confirmar cambios con formato Conventional Commits (`commit`).
- Enviar cambios locales al remoto y abrir o actualizar Pull Request (`push`, `pr`).
- Sincronizar el repositorio local con el remoto (`update`, `sync`).

## Proceso

Mapea la intención de la tarea al subcomando de `.agents/scripts/git-auto.sh`:

0. **"Enviar al repo" / flujo completo automático (recomendado):**
   Esto crea la rama si hace falta, genera el commit Conventional Commits,
   verifica el frente afectado, sube y abre el PR hacia `develop`:
   ```bash
   bash .agents/scripts/git-auto.sh auto            # auto-detecta tipo y ámbito
   bash .agents/scripts/git-auto.sh auto fix        # fuerza tipo 'fix'
   bash .agents/scripts/git-auto.sh preview         # ver plan sin tocar nada
   ```
   Si se está en `develop`/`main`/`master` **nunca se commitea ahí**:
   `auto` crea `feature/<slug>` o `fix/<slug>` automáticamente.

1. **Crear rama:**
   ```bash
   bash .agents/scripts/git-auto.sh branch feature <nombre-descriptivo>
   # o para correcciones:
   bash .agents/scripts/git-auto.sh branch fix <nombre-descriptivo>
   ```

2. **Hacer commit:**
   ```bash
   bash .agents/scripts/git-auto.sh commit "feat(api): descripcion concisa"
   ```

3. **Subir y abrir Pull Request hacia `develop`:**
   - `git-auto.sh push` sube la rama (y recuerda abrir el PR).
   - `git-auto.sh pr develop` abre o actualiza el PR **generando el título
     (Conventional Commits) y el cuerpo (archivos del diff + verificación)**
     automáticamente desde la rama.
   - En `auto` el PR hacia `develop` se abre solo al final del flujo.

4. **Sincronizar rama actual:**
   ```bash
   bash .agents/scripts/git-auto.sh sync
   ```

## Reglas Importantes

- La rama de integración activa es siempre `develop`, no `main`.
- **Nunca hagas commit directamente en `develop`, `main` o `master`**: usa una rama
  de trabajo o `git-auto.sh auto`, que la crea automáticamente.
- Nunca hagas commit si `dotnet build -warnaserror` o `npm run lint` fallan
  (`auto` ya lo verifica antes de commitear).
- Mantén mensajes de commit descriptivos y en minúsculas en el subject,
  formato Conventional Commits (`tipo(ámbito): verbo imperativo corto`).
- Incluye el ámbito (`api`, `application`, `domain`, `infra`, `admin`, `mobile`) en los commits cuando sea claro.

## Referencias

- Reglas de Git: `.agents/rules/git-workflow-rules.md`
- Script ejecutable: `.agents/scripts/git-auto.sh`
- Guía de construcción: `construccion-de-agentes.md`
