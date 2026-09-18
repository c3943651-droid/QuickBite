#!/usr/bin/env bash
# .agents/scripts/git-auto.sh
# Automatización de tareas de Git para QuickBite

set -euo pipefail

# Obtener directorio raíz del repositorio Git
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# Ramas que nunca reciben commits directos
PROTECTED_BRANCHES="main master develop"

# Base de comparación para generar mensajes/PR (vacío = árbol de trabajo)
CHG_BASE=""

usage() {
    cat << 'EOF'
Uso: git-auto.sh <comando> [argumentos]

Comandos disponibles:
  update                 Hace pull de la rama actual y muestra el status.
  branch <tipo> <nombre> Crea y cambia a una nueva rama (<tipo>/<nombre>).
  commit "<mensaje>"     Agrega todos los cambios rastreados y confirmados.
  push ["<mensaje>"]     Hace commit (opcional), sube al remoto y crea o enlaza PR.
  pr [base]              Abre/actualiza el Pull Request hacia 'base' (por defecto: develop)
                         generando título y cuerpo automáticamente desde el diff.
  sync                   Sincroniza la rama local haciendo pull y luego push.
  auto [tipo]            Flujo completo: crea rama si hace falta, genera un commit
                         Conventional Commits automático, sube, y abre el PR hacia develop.
                         [tipo] opcional: feat|feature|fix|perf|docs|test|refactor|chore
  send [tipo]            Alias de 'auto'.
  preview [tipo]         Igual que 'auto' pero solo muestra el plan, sin cambiar nada.

Notas:
  - En ramas protegidas (develop/main/master) 'auto' NO commitea en ellas:
    crea automáticamente feature/<slug> o fix/<slug> antes de confirmar.
  - El PR se abre automáticamente al final de 'auto' o con 'pr': el título sigue
    Conventional Commits y el cuerpo lista los archivos del diff + verificación.
  - Variables de entorno:
    GIT_AUTO_SKIP_VERIFY=1   omite la verificación de build/analyze automática.
EOF
    exit 1
}

cmd_update() {
    echo "==> Actualizando repositorio..."
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    git fetch origin
    git pull origin "$CURRENT_BRANCH" --rebase || true
    echo "==> Estado actual del repositorio:"
    git status -s
}

cmd_branch() {
    if [ "$#" -lt 2 ]; then
        echo "Error: Se requieren <tipo> y <nombre>. Ejemplo: git-auto.sh branch feature phase-4"
        exit 1
    fi
    TYPE="$1"
    NAME="$2"
    BRANCH_NAME="${TYPE}/${NAME}"
    if is_protected "$NAME" || is_protected "$BRANCH_NAME"; then
        echo "Error: No se puede crear una rama con nombre protegido ('$BRANCH_NAME')."
        exit 1
    fi
    echo "==> Creando y activando rama '$BRANCH_NAME'..."
    git checkout -b "$BRANCH_NAME"
}

cmd_commit() {
    if [ "$#" -lt 1 ]; then
        echo "Error: Se requiere un mensaje de commit."
        exit 1
    fi
    MSG="$1"
    echo "==> Añadiendo cambios y creando commit..."
    git add -A
    git commit -m "$MSG"
}

cmd_push() {
    if [ "$#" -ge 1 ]; then
        cmd_commit "$1"
    fi
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    echo "==> Enviando rama '$CURRENT_BRANCH' a origin..."
    git push -u origin "$CURRENT_BRANCH"
    echo "==> Para abrir el Pull Request automáticamente: git-auto.sh pr"
}

cmd_pr() {
    BASE="${1:-develop}"
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

    if is_protected "$CURRENT_BRANCH"; then
        echo "Error: '$CURRENT_BRANCH' es una rama protegida; no se abre PR desde aquí."
        exit 1
    fi

    M_BASE="$(git merge-base "$BASE" HEAD 2>/dev/null || echo "")"
    if [ -z "$M_BASE" ] || [ "$M_BASE" = "$(git rev-parse HEAD)" ]; then
        echo "Error: la rama '$CURRENT_BRANCH' no tiene commits propios respecto a '$BASE'. Nada que enviar en el PR."
        exit 1
    fi

    echo "==> Preparando Pull Request de '$CURRENT_BRANCH' hacia '$BASE'..."

    if ! command -v gh >/dev/null 2>&1; then
        REPO_URL="$(git config --get remote.origin.url | sed 's/\.git$//' | sed 's|^git@github.com:|https://github.com/|')"
        echo "Aviso: 'gh' (GitHub CLI) no está instalado."
        echo "Puedes abrir el Pull Request manualmente en:"
        echo "  $REPO_URL/compare/$BASE...$CURRENT_BRANCH"
        return 0
    fi

    if gh pr view "$CURRENT_BRANCH" >/dev/null 2>&1; then
        echo "El Pull Request ya existe:"
        gh pr view "$CURRENT_BRANCH" --web || gh pr view "$CURRENT_BRANCH"
        return 0
    fi

    # Generar título y cuerpo a partir del diff de la rama (no del árbol de trabajo)
    CHG_BASE="$BASE"
    PR_TYPE="$(detect_type)"
    PR_SCOPE="$(detect_scope)"
    PR_TITLE="$(make_header "$PR_TYPE" "$PR_SCOPE" "$(make_subject "$PR_TYPE")" 100)"
    PR_BODY="$(build_pr_body "$PR_TYPE" "$PR_SCOPE" "$PR_TITLE")"
    CHG_BASE=""

    echo ""
    echo "==> Título del PR: $PR_TITLE"
    echo "==> Creando Pull Request con gh..."
    if ! gh pr create --base "$BASE" --head "$CURRENT_BRANCH" --title "$PR_TITLE" --body "$PR_BODY"; then
        echo "Aviso: falló la creación con título automático; reintento con --fill."
        gh pr create --base "$BASE" --head "$CURRENT_BRANCH" --title "$CURRENT_BRANCH" --body "Pull Request automático para $CURRENT_BRANCH"
    fi
    gh pr view "$CURRENT_BRANCH" --json url --jq .url
}

cmd_sync() {
    cmd_update
    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    git push origin "$CURRENT_BRANCH"
}

# ---- Helpers --------------------------------------------------------------

is_protected() {
    case "$1" in
        main|master|develop) return 0 ;;
        *) return 1 ;;
    esac
}

# Devuelve las líneas "STATUS<TAB>RUTA" de los cambios a considerar:
#   - si CHG_BASE está vacío: árbol de trabajo (git status --porcelain -uall)
#   - si CHG_BASE está definido: diff de la rama frente a esa base
changes_lines() {
    if [ -n "$CHG_BASE" ]; then
        local mbase
        mbase="$(git merge-base "$CHG_BASE" HEAD 2>/dev/null || echo "$CHG_BASE")"
        git diff --name-status "$mbase" HEAD | awk -F'\t' '{ if (NF >= 2) printf "%s\t%s\n", $1, $NF }'
    else
        git status --porcelain -uall | sed -E 's/^(..) /\1\t/'
    fi
}

# Convierte un nombre de archivo en palabras legibles en minúsculas.
#  OrderCalculationRules.cs -> order calculation rules
wordify() {
    local s="${1##*/}"
    s="${s%.*}"
    s="$(printf '%s' "$s" | sed -E 's/([a-z0-9])([A-Z])/\1 \2/g; s/([A-Z]+)([A-Z][a-z])/\1 \2/g')"
    s="$(printf '%s' "$s" | sed -E 's/[._-]+/ /g' | tr -s ' ' | tr '[:upper:]' '[:lower:]' | sed 's/^ *//; s/ *$//; s/^i //')"
    printf '%s' "$s"
}

has_changes() {
    if git diff --quiet && git diff --cached --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
        return 1
    fi
    return 0
}

changed_stems() {
    local seen=" " count=0 line status f name
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        status="${line%%$'\t'*}"
        f="${line#*$'\t'}"
        f="${f##* -> }"
        name="$(wordify "$f")"
        [ -z "$name" ] && continue
        case "$seen" in
            *" $name "*) continue ;;
        esac
        seen="$seen$name "
        printf '%s\n' "$name"
        count=$((count + 1))
        [ "$count" -ge 2 ] && break
    done <<< "$(changes_lines)"
}

detect_type() {
    if [ -n "${1:-}" ] && [ "$1" != "auto" ]; then
        case "$1" in
            feature) printf 'feat' ;;
            *) printf '%s' "$1" ;;
        esac
        return
    fi
    local total=0 doc_count=0 test_count=0 new_count=0 status f line
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        status="${line%%$'\t'*}"
        f="${line#*$'\t'}"
        f="${f##* -> }"
        total=$((total + 1))
        case "$f" in
            *.md|docs/*|PLAN_DE_FASES_*) doc_count=$((doc_count + 1)) ;;
        esac
        case "$f" in
            backend/tests/*|*/Tests/*|*Tests.cs|*_test.dart|mobile/test/*) test_count=$((test_count + 1)) ;;
        esac
        case "$status" in
            \?\?|A*) new_count=$((new_count + 1)) ;;
        esac
    done <<< "$(changes_lines)"
    if [ "$total" -gt 0 ] && [ "$doc_count" -eq "$total" ]; then
        printf 'docs'
    elif [ "$total" -gt 0 ] && [ "$test_count" -eq "$total" ]; then
        printf 'test'
    elif [ "$new_count" -gt 0 ]; then
        printf 'feat'
    else
        printf 'chore'
    fi
}

detect_scope() {
    local -A counts=()
    local f s line best="" bestcount=0
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        f="${line#*$'\t'}"
        f="${f##* -> }"
        case "$f" in
            backend/src/QuickBite.Api/*) s=api ;;
            backend/src/QuickBite.Application/*) s=application ;;
            backend/src/QuickBite.Domain/*) s=domain ;;
            backend/src/QuickBite.Shared/*) s=shared ;;
            backend/src/QuickBite.AdminBlazor/*) s=admin ;;
            backend/src/QuickBite.Infrastructure/*Migrations*) s=db ;;
            backend/src/QuickBite.Infrastructure/*) s=infra ;;
            backend/*) s=backend ;;
            mobile/*) s=mobile ;;
            docs/*) s=docs ;;
            *) s=other ;;
        esac
        counts[$s]=$(( ${counts[$s]:-0} + 1 ))
    done <<< "$(changes_lines)"
    for k in "${!counts[@]}"; do
        if [ "${counts[$k]}" -gt "$bestcount" ] && [ "$k" != "other" ]; then
            best="$k"
            bestcount="${counts[$k]}"
        fi
    done
    printf '%s' "$best"
}

verb_for() {
    case "$1" in
        feat) printf 'add' ;;
        fix) printf 'fix' ;;
        perf) printf 'optimize' ;;
        docs) printf 'update' ;;
        test) printf 'test' ;;
        refactor) printf 'refactor' ;;
        *) printf 'update' ;;
    esac
}

make_slug() {
    local scope="$1" first
    first="$(changed_stems | head -1)"
    [ -z "$first" ] && first="changes"
    first="$(printf '%s' "$first" | tr ' ' '-')"
    if [ -n "$scope" ]; then
        printf '%s-%s' "$scope" "$first"
    else
        printf '%s' "$first"
    fi
}

make_subject() {
    local verb words
    words="$(changed_stems | awk 'NR>1 {s=s" and "} {s=s$0} END {print s}')"
    [ -z "$words" ] && words="changes"
    verb="$(verb_for "$1")"
    printf '%s %s' "$verb" "$words"
}

# Compone la cabecera "<tipo>[(<ámbito>)]: <asunto>" truncada a 'max' caracteres.
make_header() {
    local type="$1" scope="$2" subject="$3" max="${4:-72}" header
    if [ -n "$scope" ] && [ "$scope" != "$type" ]; then
        header="${type}(${scope}): ${subject}"
    else
        header="${type}: ${subject}"
    fi
    if [ "${#header}" -gt "$max" ]; then
        header="$(printf '%s' "$header" | cut -c1-"$max" | sed 's/ *$//')"
        header="${header}..."
    fi
    printf '%s' "$header"
}

build_message() {
    local type="$1" scope="$2"
    printf '%s\n\nCambios incluidos:\n' "$(make_header "$type" "$scope" "$(make_subject "$type")")"
    git status --porcelain -uall | sed 's/^/  /'
}

label_status() {
    case "$1" in
        \?\?|A*) printf 'añadido' ;;
        M*) printf 'modificado' ;;
        D*) printf 'eliminado' ;;
        R*) printf 'renombrado' ;;
        C*) printf 'copiado' ;;
        *) printf 'cambio' ;;
    esac
}

verify_hint() {
    case "$1" in
        api|application|domain|infra|db|shared|backend)
            printf '%s\n' '- Backend: `dotnet build backend/src/QuickBite.sln -warnaserror` y `dotnet test backend/tests/QuickBite.Tests.Unit/`'
            ;;
        mobile)
            printf '%s\n' '- Móvil: `flutter analyze` y `flutter test`'
            ;;
        *)
            printf '%s\n' '- Ajustar verificación según el frente afectado (`dotnet build`/`flutter analyze`)'
            ;;
    esac
}

build_pr_body() {
    local type="$1" scope="$2" title="$3" st f
    printf '# %s\n\n## Cambios en este PR\n\n' "$title"
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        st="${line%%$'\t'*}"
        f="${line#*$'\t'}"
        f="${f##* -> }"
        printf -- '- [%s] %s\n' "$(label_status "$st")" "$f"
    done <<< "$(changes_lines)"
    printf '\n## Verificación\n\n'
    verify_hint "$scope"
}

resolve_branch() {
    # Define las vars globales TYPE, SCOPE, BRANCH_NAME y NEED_BRANCH según la
    # situación del repositorio. No modifica nada.
    TYPE="$(detect_type "${1:-}")"
    SCOPE="$(detect_scope)"
    NEED_BRANCH=0
    BRANCH_NAME="$(git rev-parse --abbrev-ref HEAD)"
    if is_protected "$BRANCH_NAME"; then
        NEED_BRANCH=1
        local prefix="$TYPE"
        [ "$prefix" = "feat" ] && prefix="feature"
        local base branch n=2
        branch="${prefix}/$(make_slug "$SCOPE")"
        base="$branch"
        while git show-ref --verify --quiet "refs/heads/$branch"; do
            branch="${base}${n}"
            n=$((n + 1))
        done
        BRANCH_NAME="$branch"
    fi
}

run_verification() {
    local scope="$1"
    [ "${GIT_AUTO_SKIP_VERIFY:-0}" = "1" ] && return 0
    case "$scope" in
        api|application|domain|infra|db|shared|backend)
            if command -v dotnet >/dev/null 2>&1; then
                echo "==> Verificando backend (dotnet build -warnaserror)..."
                dotnet build "$REPO_ROOT/backend/src/QuickBite.sln" -warnaserror
            else
                echo "==> Aviso: dotnet no encontrado; se omite la verificación del backend."
            fi
            ;;
        mobile)
            if command -v flutter >/dev/null 2>&1; then
                echo "==> Verificando móvil (flutter analyze)..."
                (cd "$REPO_ROOT/mobile" && flutter analyze)
            else
                echo "==> Aviso: flutter no encontrado; se omite la verificación del móvil."
            fi
            ;;
    esac
}

# ---- Comando auto/send/preview --------------------------------------------

cmd_auto() {
    if ! has_changes; then
        echo "==> No hay cambios pendientes. Nada que enviar."
        git status -s
        exit 0
    fi

    resolve_branch "${1:-}"

    CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    if [ "$NEED_BRANCH" -eq 1 ]; then
        echo "==> Estás en '$CURRENT_BRANCH' (rama protegida). Creando rama '$BRANCH_NAME'..."
        git checkout -b "$BRANCH_NAME"
    else
        echo "==> Ya estás en la rama de trabajo '$BRANCH_NAME'."
    fi

    git add -A
    run_verification "$SCOPE"

    MSG="$(build_message "$TYPE" "$SCOPE")"
    echo ""
    echo "==> Commit generado:"
    printf '%s\n' "$MSG"
    printf '%s\n' "$MSG" | git commit -F -

    echo ""
    echo "==> Subiendo rama '$BRANCH_NAME' a origin..."
    git push -u origin "$BRANCH_NAME"

    echo ""
    cmd_pr "develop"
}

cmd_preview() {
    if ! has_changes; then
        echo "==> No hay cambios pendientes."
        git status -s
        exit 0
    fi
    resolve_branch "${1:-}"
    echo "==> Tipo detectado: $TYPE"
    echo "==> Ámbito detectado: ${SCOPE:---}"
    if [ "$NEED_BRANCH" -eq 1 ]; then
        echo "==> Rama a crear:        $BRANCH_NAME (desde $(git rev-parse --abbrev-ref HEAD))"
    else
        echo "==> Rama actual:         $BRANCH_NAME"
    fi
    echo ""
    echo "==> Mensaje de commit propuesto:"
    build_message "$TYPE" "$SCOPE"
}

# ---- Despacho de comandos ---------------------------------------------------

if [ "$#" -lt 1 ]; then
    usage
fi

ACTION="$1"
shift

case "$ACTION" in
    update)
        cmd_update "$@"
        ;;
    branch)
        cmd_branch "$@"
        ;;
    commit)
        cmd_commit "$@"
        ;;
    push)
        cmd_push "$@"
        ;;
    pr)
        cmd_pr "$@"
        ;;
    sync)
        cmd_sync "$@"
        ;;
    auto|send)
        cmd_auto "$@"
        ;;
    preview)
        cmd_preview "$@"
        ;;
    *)
        echo "Comando desconocido: $ACTION"
        usage
        ;;
esac