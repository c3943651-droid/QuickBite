import { useMemo, useState } from "react"
import { toast } from "sonner"
import { cn } from "cn"
import { LayoutGrid, List, Pencil, Plus, Power, Trash2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { ConfirmDialog } from "@/components/common/confirm-dialog"
import { Skeleton } from "@/components/ui/skeleton"
import { ErrorState } from "@/components/common/error-state"
import { StatusChip } from "@/components/common/status-chip"
import { CategoryFormDialog } from "@/components/features/categories/category-form-dialog"
import {
  CategoryGrid,
  CategoryGridSkeleton,
} from "@/components/features/categories/category-grid"
import {
  useAdminCategories,
  useDeleteCategory,
  useUpdateCategory,
  type CategoryResponse,
} from "@/lib/api/admin/categories"
import { getApiErrorMessage } from "@/lib/api/error"

function CategoriesLoadingState() {
  return (
    <Card className="p-4">
      <div className="space-y-3">
        {Array.from({ length: 5 }).map((_, i) => (
          <Skeleton key={i} className="h-12 rounded-lg" />
        ))}
      </div>
    </Card>
  )
}

export default function CategoriesPage() {
  const [sortKey, setSortKey] = useState("")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc")
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<CategoryResponse | null>(null)
  const [view, setView] = useState<"grid" | "list">("grid")
  const [pendingId, setPendingId] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<CategoryResponse | null>(null)
  const [toggleTarget, setToggleTarget] = useState<CategoryResponse | null>(null)

  const { data, isLoading, isError, refetch } = useAdminCategories()
  const updateCategory = useUpdateCategory()
  const deleteCategory = useDeleteCategory()

  const sortedData = useMemo(() => {
    const items = data ? [...data] : []
    if (!sortKey) return items
    items.sort((a, b) => {
      const av = a[sortKey as keyof CategoryResponse]
      const bv = b[sortKey as keyof CategoryResponse]
      const cmp =
        typeof av === "number" && typeof bv === "number"
          ? av - bv
          : String(av ?? "").localeCompare(String(bv ?? ""), "es")
      return sortDir === "asc" ? cmp : -cmp
    })
    return items
  }, [data, sortKey, sortDir])

  function openCreate() {
    setEditing(null)
    setDialogOpen(true)
  }

  function openEdit(category: CategoryResponse) {
    setEditing(category)
    setDialogOpen(true)
  }

  async function confirmToggleActive() {
    if (!toggleTarget) return
    const target = toggleTarget
    setPendingId(target.id)
    try {
      await updateCategory.mutateAsync({
        id: target.id,
        data: { activo: !target.activo },
      })
      toast.success(
        target.activo ? "Categoría desactivada correctamente" : "Categoría activada correctamente",
      )
      setToggleTarget(null)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo cambiar el estado. Inténtalo de nuevo."))
    } finally {
      setPendingId(null)
    }
  }

  async function handleDelete() {
    if (!deleteTarget) return
    try {
      await deleteCategory.mutateAsync({ id: deleteTarget.id })
      toast.success(`Categoría "${deleteTarget.nombre}" eliminada`)
      setDeleteTarget(null)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo eliminar la categoría"))
    }
  }

  const columns: DataColumn<CategoryResponse>[] = [
    {
      key: "nombre",
      header: "Nombre",
      sortable: true,
      render: (category) => <span className="font-medium">{category.nombre}</span>,
    },
    {
      key: "descripcion",
      header: "Descripción",
      render: (category) =>
        category.descripcion ? (
          <span className="text-muted-foreground line-clamp-1">{category.descripcion}</span>
        ) : (
          <span className="text-muted-foreground">—</span>
        ),
    },
    {
      key: "orden",
      header: "Orden",
      sortable: true,
      className: "text-center tabular-nums",
      render: (category) => category.orden,
    },
    {
      key: "estado",
      header: "Estado",
      sortable: true,
      render: (category) =>
        category.activo ?
          <StatusChip status="Activo" />
        : <StatusChip status="Inactivo" />,
    },
    {
      key: "acciones",
      header: "",
      className: "text-right",
      render: (category) => (
        <div
          className="flex justify-end gap-1"
          onClick={(event) => event.stopPropagation()}
        >
          <Button
            variant="ghost"
            size="sm"
            aria-label="Editar"
            disabled={pendingId === category.id}
            onClick={() => openEdit(category)}
          >
            <Pencil className="size-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            aria-label={category.activo ? "Desactivar" : "Activar"}
            disabled={pendingId === category.id}
            onClick={() => setToggleTarget(category)}
          >
            <Power className={cn("size-4", !category.activo && "text-muted-foreground")} />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            className="text-destructive hover:text-destructive"
            aria-label="Eliminar"
            disabled={pendingId === category.id}
            onClick={() => setDeleteTarget(category)}
          >
            <Trash2 className="size-4" />
          </Button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Categorías</h1>
          <p className="text-muted-foreground text-sm">
            Organiza los productos del catálogo.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-0.5 rounded-lg bg-zinc-100 p-0.5">
            <Button
              variant={view === "grid" ? "default" : "ghost"}
              size="icon-sm"
              aria-label="Vista de tarjetas"
              aria-pressed={view === "grid"}
              className={cn("rounded-[6px]", view !== "grid" && "text-zinc-500")}
              onClick={() => setView("grid")}
            >
              <LayoutGrid className="size-4" />
            </Button>
            <Button
              variant={view === "list" ? "default" : "ghost"}
              size="icon-sm"
              aria-label="Vista de tabla"
              aria-pressed={view === "list"}
              className={cn("rounded-[6px]", view !== "list" && "text-zinc-500")}
              onClick={() => setView("list")}
            >
              <List className="size-4" />
            </Button>
          </div>
          <Button onClick={openCreate}>
            <Plus className="size-4" />
            Nueva categoría
          </Button>
        </div>
      </div>

      {isError ? (
        <ErrorState
          title="No se pudieron cargar las categorías"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : view === "grid" ? (
        isLoading ? (
          <CategoryGridSkeleton />
        ) : (data ?? []).length > 0 ? (
          <CategoryGrid
            categories={sortedData}
            onEdit={openEdit}
            onToggle={setToggleTarget}
            onDelete={setDeleteTarget}
            pendingId={pendingId}
          />
        ) : (
          <div className="mt-4 rounded-xl border border-dashed border-zinc-200 bg-zinc-50/50 p-8 text-center">
            <p className="text-sm font-medium text-zinc-600">Sin categorías</p>
            <p className="mt-1 text-sm text-zinc-500">Crea tu primera categoría para comenzar.</p>
          </div>
        )
      ) : isLoading ? (
        <CategoriesLoadingState />
      ) : (
        <DataTable
          columns={columns}
          data={sortedData}
          rowKey={(category) => category.id}
          sortKey={sortKey}
          sortDir={sortDir}
          onSortChange={(key, dir) => {
            setSortKey(key)
            setSortDir(dir)
          }}
          emptyTitle="Sin categorías"
          emptyDescription="Crea tu primera categoría para comenzar."
        />
      )}

      <CategoryFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        category={editing}
      />

      <ConfirmDialog
        open={toggleTarget !== null}
        onOpenChange={(open) => {
          if (!open) setToggleTarget(null)
        }}
        title={
          toggleTarget
            ? `¿${toggleTarget.activo ? "Desactivar" : "Activar"} "${toggleTarget.nombre}"?`
            : ""
        }
        description={
          toggleTarget
            ? toggleTarget.activo
              ? "Esta categoría dejará de mostrarse en el catálogo digital de forma inmediata."
              : "La categoría volverá a estar disponible en el catálogo digital."
            : undefined
        }
        confirmLabel={toggleTarget?.activo ? "Desactivar" : "Activar"}
        tone={toggleTarget?.activo ? "amber" : "default"}
        loading={updateCategory.isPending}
        onConfirm={() => void confirmToggleActive()}
      />

      <ConfirmDialog
        open={deleteTarget !== null}
        onOpenChange={(open) => !open && setDeleteTarget(null)}
        title="¿Eliminar categoría?"
        description={
          deleteTarget
            ? `Se eliminará "${deleteTarget.nombre}". Esta acción no se puede deshacer.`
            : undefined
        }
        confirmLabel="Eliminar"
        destructive
        loading={deleteCategory.isPending}
        onConfirm={() => void handleDelete()}
      />
    </div>
  )
}