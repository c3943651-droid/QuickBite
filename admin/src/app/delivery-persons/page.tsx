import { useMemo, useState } from "react"
import { toast } from "sonner"
import { Ban, Eye, Pencil, Plus, Search } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { ErrorState } from "@/components/common/error-state"
import { StatusChip } from "@/components/common/status-chip"
import { ConfirmDialog } from "@/components/common/confirm-dialog"
import { DeliveryPersonFormDialog } from "@/components/features/delivery-persons/delivery-person-form-dialog"
import { DeliveryPersonDetailDialog } from "@/components/features/delivery-persons/delivery-person-detail-dialog"
import { useAdminDeliveryPersons, type DeliveryPersonListItem } from "@/lib/api/admin/orders"
import {
  DELIVERY_PERSON_STATUS_LIST,
  deliveryPersonStatusLabel,
  useDeactivateDeliveryPerson,
  type DeliveryPersonStatusValue,
} from "@/lib/api/admin/delivery-persons"
import { getApiErrorMessage } from "@/lib/api/error"
import { useDebouncedValue } from "@/hooks/use-debounced-value"

function initials(nombre: string): string {
  return nombre
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase()
}

export default function DeliveryPersonsPage() {
  const [search, setSearch] = useState("")
  const debouncedSearch = useDebouncedValue(search, 300)
  const [estado, setEstado] = useState<"" | DeliveryPersonStatusValue>("")
  const [sortKey, setSortKey] = useState("")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc")
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<DeliveryPersonListItem | null>(null)
  const [detail, setDetail] = useState<DeliveryPersonListItem | null>(null)
  const [deactivating, setDeactivating] = useState<DeliveryPersonListItem | null>(null)

  const { data, isLoading, isFetching, isError, refetch } = useAdminDeliveryPersons({
    params: { estado: estado || undefined, page: 1, limit: 100 },
  })
  const deactivate = useDeactivateDeliveryPerson()

  const filtered = useMemo(() => {
    const items = data?.data ?? []
    const q = debouncedSearch.trim().toLowerCase()
    if (!q) return items
    return items.filter((item) =>
      [item.nombre, item.email, item.telefono ?? ""].some((value) =>
        value.toLowerCase().includes(q),
      ),
    )
  }, [data, debouncedSearch])

  const sorted = useMemo(() => {
    const copy = [...filtered]
    if (!sortKey) return copy
    const dir = sortDir === "asc" ? 1 : -1
    copy.sort((a, b) => {
      const av = a[sortKey as keyof DeliveryPersonListItem]
      const bv = b[sortKey as keyof DeliveryPersonListItem]
      if (typeof av === "number" && typeof bv === "number") return (av - bv) * dir
      return String(av ?? "").localeCompare(String(bv ?? "")) * dir
    })
    return copy
  }, [filtered, sortKey, sortDir])

  const total = sorted.length
  const totalPages = Math.max(1, Math.ceil(total / limit))
  const currentPage = Math.min(page, totalPages)
  const rows = sorted.slice((currentPage - 1) * limit, currentPage * limit)

  function openCreate() {
    setEditing(null)
    setDialogOpen(true)
  }

  function openEdit(repartidor: DeliveryPersonListItem) {
    setEditing(repartidor)
    setDialogOpen(true)
  }

  async function confirmDeactivate() {
    if (!deactivating) return
    const target = deactivating
    setDeactivating(null)
    try {
      await deactivate.mutateAsync(target.usuarioId)
      toast.success(`${target.nombre} fue desactivado`)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo desactivar al repartidor"))
    }
  }

  const columns: DataColumn<DeliveryPersonListItem>[] = [
    {
      key: "nombre",
      header: "Repartidor",
      sortable: true,
      render: (item) => (
        <div className="flex min-w-0 items-center gap-3">
          <div className="bg-primary/10 text-primary flex size-9 shrink-0 items-center justify-center rounded-full text-xs font-semibold">
            {initials(item.nombre)}
          </div>
          <div className="min-w-0">
            <p className="truncate font-medium">{item.nombre}</p>
            <p className="truncate text-muted-foreground text-xs">{item.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "telefono",
      header: "Teléfono",
      render: (item) => item.telefono ?? <span className="text-muted-foreground">—</span>,
    },
    {
      key: "vehiculo",
      header: "Vehículo",
      render: (item) =>
        item.vehiculo ? (
          item.vehiculo
        ) : (
          <span className="text-muted-foreground">—</span>
        ),
    },
    {
      key: "estado",
      header: "Estado",
      render: (item) => <StatusChip status={deliveryPersonStatusLabel(item.estadoDisponibilidad)} />,
    },
    {
      key: "pedidosActivos",
      header: "Pedidos activos",
      className: "tabular-nums",
      render: (item) =>
        item.estadoDisponibilidad === "ocupado" ? (
          <span className="font-medium text-amber-600 dark:text-amber-400">1+</span>
        ) : (
          <span className="text-muted-foreground">0</span>
        ),
    },
    {
      key: "entregasCompletadas",
      header: "Entregas",
      sortable: true,
      className: "tabular-nums",
      render: (item) => item.entregasCompletadas,
    },
    {
      key: "acciones",
      header: "",
      className: "text-right",
      render: (item) => (
        <div
          className="flex justify-end gap-1"
          onClick={(event) => event.stopPropagation()}
        >
          <Button
            variant="ghost"
            size="sm"
            aria-label="Ver detalle"
            disabled={deactivate.isPending}
            onClick={() => setDetail(item)}
          >
            <Eye className="size-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            aria-label="Editar"
            disabled={deactivate.isPending}
            onClick={() => openEdit(item)}
          >
            <Pencil className="size-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            aria-label="Desactivar"
            disabled={deactivate.isPending}
            onClick={() => setDeactivating(item)}
            className="text-destructive hover:text-destructive"
          >
            <Ban className="size-4" />
          </Button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Repartidores</h1>
          <p className="text-muted-foreground text-sm">
            Gestiona el equipo de reparto y su disponibilidad.
          </p>
        </div>
        <Button onClick={openCreate}>
          <Plus className="size-4" />
          Nuevo repartidor
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <div className="relative min-w-52 flex-1 sm:max-w-xs">
          <Search className="text-muted-foreground pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2" />
          <Input
            placeholder="Buscar por nombre, email o teléfono…"
            value={search}
            onChange={(event) => {
              setSearch(event.target.value)
              setPage(1)
            }}
            className="pl-8"
          />
        </div>
        <Select
          value={estado}
          onValueChange={(value) => {
            setEstado(value as "" | DeliveryPersonStatusValue)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-44">
            <SelectValue placeholder="Todos los estados" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Todos los estados</SelectItem>
            {DELIVERY_PERSON_STATUS_LIST.map((status) => (
              <SelectItem key={status.value} value={status.value}>
                {status.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {isError ? (
        <ErrorState
          title="No se pudieron cargar los repartidores"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : (
        <DataTable
          columns={columns}
          data={rows}
          rowKey={(item) => item.usuarioId}
          loading={isLoading || isFetching}
          currentPage={currentPage}
          pageSize={limit}
          totalItems={total}
          onPageChange={setPage}
          onPageSizeChange={(size) => {
            setLimit(size)
            setPage(1)
          }}
          sortKey={sortKey}
          sortDir={sortDir}
          onSortChange={(key, dir) => {
            setSortKey(key)
            setSortDir(dir)
            setPage(1)
          }}
          emptyTitle="Sin repartidores"
          emptyDescription="Ajusta los filtros o registra un nuevo repartidor."
        />
      )}

      <DeliveryPersonFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        repartidor={editing}
      />

      <DeliveryPersonDetailDialog
        repartidor={detail}
        onOpenChange={(open) => !open && setDetail(null)}
      />

      <ConfirmDialog
        open={Boolean(deactivating)}
        onOpenChange={(open) => {
          if (!open) setDeactivating(null)
        }}
        title="Desactivar repartidor"
        description={
          deactivating
            ? `¿Seguro que quieres desactivar a ${deactivating.nombre}? No podrá recibir entregas mientras esté inactivo.`
            : undefined
        }
        confirmLabel="Desactivar"
        cancelLabel="Cancelar"
        tone="amber"
        loading={deactivate.isPending}
        onConfirm={() => void confirmDeactivate()}
      />
    </div>
  )
}