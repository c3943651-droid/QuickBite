# Guía de construcción de `.agents`

Esta guía describe cómo se construye la carpeta `.agents` de este repositorio, para que otros desarrolladores, otras IDEs y otros agentes de IA puedan **replicarla** en sus propios proyectos.

## ¿Qué es `.agents`?

Es un directorio de convenciones compartido dentro del repo que define **cómo trabaja un agente de IA con Git** en este proyecto. No es un estándar oficial: es un patrón autónomo que cualquier agente o IDE puede leer y seguir. Se compone de tres subcarpetas:

```
.agents/
├── rules/          → reglas de comportamiento (p. ej. flujo de Git)
├── scripts/        → scripts ejecutables (automatización concreta)
└── skills/         → skills reutilizables (SKILL.md) que usan las reglas y scripts
```

La filosofía: **reglas** (qué se debe hacer) + **scripts** (los "músculos" que lo hacen) + **skills** (la capa que un agente carga para saber cuándo y cómo usar los scripts).

---

## 1. Cómo replicarlo en otro proyecto

En la raíz del repo:

```bash
mkdir -p .agents/rules .agents/scripts .agents/skills
```

### a) `rules/` — reglas

Escribe un Markdown con las convenciones del proyecto. Contenido típico para Git:

- Rama por defecto y política de ramas (`feature/`, `fix/`).
- Formato de mensajes de commit (Conventional Commits).
- Política de Pull Requests (integración a `main`).
- Rutinas de sincronización local (pull antes de trabajar).
- Higiene: respetar `.gitignore`, revisar `git status`.

Archivo ejemplo: `.agents/rules/git-workflow-rules.md`

Las reglas son **léelas y síguelas**; cualquier agente humano o de IA las entiende sin instalación.

### b) `scripts/` — automatización ejecutable

Un script POSIX simple (Bash) que centraliza los comandos. Mantenlo:

- **Ejecutable**: `chmod +x .agents/scripts/*.sh`
- **Autocontenido**: usa `git` puro; opcionalmente `gh` (GitHub CLI) para PRs.
- **Reporta por pasos**: entradas `echo` claras y `exit` en errores.

Archivo ejemplo: `.agents/scripts/git-auto.sh`

Interfaz común (subcomandos):
- `update` → pull + status
- `branch <tipo> <nombre>` → crea y activa la rama
- `commit "<mensaje>"` → add + commit
- `push ["<mensaje>"]` → commit + push + PR
- `pr` → abre Pull Request hacia `main`
- `sync` → pull + push

### c) `skills/` — skill reutilizable (SKILL.md)

Un skill es una instrucción que un agente **carga bajo demanda** cuando la tarea coincide. El formato está pensado para agentes que soportan "skills" (como opencode, Cursor, Claude Code, etc.), pero como es Markdown, cualquier agente puede leerlo.

Estructura:
```
skills/
└── <nombre-del-skill>/
    └── SKILL.md
```

`SKILL.md` debe incluir (frontmatter + cuerpo):

```markdown
---
name: git-workflow
description: Automatiza branch/commit/push/PR usando .agents/scripts/git-auto.sh
---

# Git Workflow Skill

## Cuándo usar
<peticiones del usuario que deben activar el skill>

## Proceso
<pasos: mapear petición → subcomando → ejecutar `bash .agents/scripts/git-auto.sh <subcomando>`>

## Reglas importantes
<convenciones que el agente debe respetar>

## Referencias
- Reglas: .agents/rules/git-workflow-rules.md
- Script: .agents/scripts/git-auto.sh
```

El campo `description` del frontmatter es clave: es lo que el agente lee para decidir si carga el skill.

---

## 2. Dependencias

| Dependencia | Necesaria para | Nota |
|---|---|---|
| `git` | Todo | Obligatoria |
| `gh` (GitHub CLI) | Crear PRs automáticos | Opcional; sin él se muestra URL manual |

`gh` **no consume RAM** en segundo plano: es un binario que solo corre al invocarlo. Se instala con el gestor de la distro o descargando el binario estático a `~/.local/bin`.

---

## 3. Flujo de ejemplo (quién hace qué)

1. El **usuario** pide: "crea una rama para el login y súbela".
2. El **agente** detecta que la tarea coincide con el skill `git-workflow` (por su `description`).
3. El **agente** carga `.agents/skills/git-workflow/SKILL.md`.
4. El **skill** le dice que ejecute el script:
   `bash .agents/scripts/git-auto.sh branch feature login` y luego `... push "feat: login"`.
5. El **script** usa git (y `gh` si está disponible) para: crear la rama, commitear, hacer push y abrir el PR.
6. Las **reglas** `.agents/rules/git-workflow-rules.md` garantizan que el mensaje/rama/PR sigan las convenciones.

---

## 4. Buenas prácticas

- **Un único script**: casi toda la lógica vive en `git-auto.sh`; el skill solo la orquesta.
- **Sin `gh` → degradación elegante**: si `gh` no está, el script avisa y da la URL del PR.
- **Markdown universal**: reglas y skills son Markdown, legibles por humanos y por cualquier agente.
- **Autocontenido**: el script no depende de rutas absolutas del autor (resuelve su raíz relativa).
- **Probado**: verificar siempre con `bash -n` (sintaxis) antes de compartir.
