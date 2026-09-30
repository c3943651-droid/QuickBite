import { useMemo, useState } from "react"
import { toast } from "sonner"
import { cn } from "cn"
import { Pencil, Plus, Power, Trash2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card } from "@/components/ui/card"
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { ConfirmDialog } from "@/components/common/confirm-dialog"
import { Skeleton } from "@/components/ui/skeleton"
import { ErrorState } from "@/components/common/error-state"
import { StatusChip } from "@/components/common/status-chip"
import { PromotionFormDialog } from "@/components/features/promotions/promotion-form-dialog"
import {
  useAdminPromotions,
  useDeletePromotion,
  useUpdatePromotion,
  type PromotionResponse,
} from "@/lib/api/admin/promotions"
import { getApiErrorMessage } from "@/lib/api/error"

function PromotionsLoadingState() {
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

export default function PromotionsPage() {
  const [sortKey, setSortKey] = useState("")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc")
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<PromotionResponse | null>(null)
  const [pendingId, setPendingId] = useState<string | null>(null)
  const [deleteTarget, setDeleteTarget] = useState<PromotionResponse | null>(null)
  const [toggleTarget, setToggleTarget] = useState<PromotionResponse | null>(null)

  const { data, isLoading, isError, refetch } = useAdminPromotions()
  const updatePromotion = useUpdatePromotion()
  const deletePromotion = useDeletePromotion()

  const sortedData = useMemo(() => {
    const items = data ? [...data] : []
    if (!sortKey) return items
    items.sort((a, b) => {
      const av = a[sortKey as keyof PromotionResponse]
      const bv = b[sortKey as keyof PromotionResponse]
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

  function openEdit(promotion: PromotionResponse) {
    setEditing(promotion)
    setDialogOpen(true)
  }

  async function confirmToggleActive() {
    if (!toggleTarget) return
    const target = toggleTarget
    setPendingId(target.id)
    try {
      await updatePromotion.mutateAsync({
        id: target.id,
        data: { activa: true },
      })
      toast.success("Promoción activada correctamente")
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
      await deletePromotion.mutateAsync({ id: deleteTarget.id })
      toast.success(`Promoción "${deleteTarget.titulo}" eliminada`)
      setDeleteTarget(null)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo eliminar la promoción"))
    }
  }

  const columns: DataColumn<PromotionResponse>[] = [
    {
      key: "titulo",
      header: "Título",
      sortable: true,
      render: (promotion) => <span className="font-medium">{promotion.titulo}</span>,
    },
    {
      key: "subtitulo",
      header: "Subtítulo",
      render: (promotion) =>
        promotion.subtitulo ? (
          <span className="text-muted-foreground line-clamp-1">{promotion.subtitulo}</span>
        ) : (
          <span className="text-muted-foreground">—</span>
        ),
    },
    {
      key: "colorHex",
      header: "Color",
      render: (promotion) => (
        <div className="flex items-center gap-2">
          <div
            className="size-5 rounded-full border border-zinc-200"
            style={{ backgroundColor: promotion.colorHex }}
          />
          <span className="text-xs text-muted-foreground">{promotion.colorHex}</span>
        </div>
      ),
    },
    {
      key: "acciones",
      header: "",
      className: "text-right",
      render: (promotion) => (
        <div
          className="flex justify-end gap-1"
          onClick={(event) => event.stopPropagation()}
        >
          <Button
            variant="ghost"
            size="sm"
            aria-label="Editar"
            disabled={pendingId === promotion.id}
            onClick={() => openEdit(promotion)}
          >
            <Pencil className="size-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            aria-label="Eliminar"
            disabled={pendingId === promotion.id}
            onClick={() => setDeleteTarget(promotion)}
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
          <h1 className="text-2xl font-semibold">Promociones</h1>
          <p className="text-muted-foreground text-sm">
            Gestiona los banners promocionales del catálogo.
          </p>
        </div>
        <Button onClick={openCreate}>
          <Plus className="size-4" />
          Nueva promoción
        </Button>
      </div>

      {isError ? (
        <ErrorState
          title="No se pudieron cargar las promociones"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : isLoading ? (
        <PromotionsLoadingState />
      ) : (
        <DataTable
          columns={columns}
          data={sortedData}
          rowKey={(promotion) => promotion.id}
          sortKey={sortKey}
          sortDir={sortDir}
          onSortChange={(key, dir) => {
            setSortKey(key)
            setSortDir(dir)
          }}
          emptyTitle="Sin promociones"
          emptyDescription="Crea tu primera promoción para mostrar en el catálogo."
        />
      )}

      <PromotionFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        promotion={editing}
      />

      <ConfirmDialog
        open={deleteTarget !== null}
        onOpenChange={(open) => !open && setDeleteTarget(null)}
        title="¿Eliminar promoción?"
        description={
          deleteTarget
            ? `Se eliminará "${deleteTarget.titulo}". Esta acción no se puede deshacer.`
            : undefined
        }
        confirmLabel="Eliminar"
        destructive
        loading={deletePromotion.isPending}
        onConfirm={() => void handleDelete()}
      />
    </div>
  )
}
