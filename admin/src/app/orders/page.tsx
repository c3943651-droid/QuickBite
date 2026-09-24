import { useState, type ReactNode } from "react"
import {
  Download,
  Eye,
  RefreshCw,
  Search,
  type LucideIcon,
} from "lucide-react"
import { cn } from "cn"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Card } from "@/components/ui/card"
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { ErrorState } from "@/components/common/error-state"
import { StatusChip } from "@/components/common/status-chip"
import { OrderDetailDialog } from "@/components/features/orders/order-detail-dialog"
import {
  ORDER_STATUS_LABELS,
  type AdminOrderListItem,
  useAdminOrders,
} from "@/lib/api/admin/orders"
import { exportCSV } from "@/lib/csv"
import { formatCurrency, formatDateTime } from "@/lib/format"
import { useDebouncedValue } from "@/hooks/use-debounced-value"

const PAGE_SIZE_DEFAULT = 10

const STATUS_FILTERS: Array<{ value: string; label: string }> = Object.entries(
  ORDER_STATUS_LABELS,
).map(([value, label]) => ({ value, label }))

function OrdersLoadingState() {
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2">
        {Array.from({ length: 6 }).map((_, i) => (
          <div key={i} className="h-9 w-28 animate-pulse rounded-md bg-muted" />
        ))}
      </div>
      <Card className="p-4">
        <div className="h-64 animate-pulse rounded-lg bg-muted/60" />
      </Card>
    </div>
  )
}

export default function OrdersPage() {
  const [searchInput, setSearchInput] = useState("")
  const [estado, setEstado] = useState("all")
  const [fechaDesde, setFechaDesde] = useState("")
  const [fechaHasta, setFechaHasta] = useState("")
  const [page, setPage] = useState(1)
  const [pageSize, setPageSize] = useState(PAGE_SIZE_DEFAULT)
  const [selectedId, setSelectedId] = useState<string | null>(null)

  const search = useDebouncedValue(searchInput.trim())

  const { data, isLoading, isError, refetch, isRefetching } = useAdminOrders({
    params: {
      search: search || undefined,
      estado: estado !== "all" ? estado : undefined,
      fechaDesde: fechaDesde || undefined,
      fechaHasta: fechaHasta || undefined,
      page,
      limit: pageSize,
    },
  })

  function resetPage() {
    setPage(1)
  }

  function handleSearchChange(value: string) {
    setSearchInput(value)
    resetPage()
  }

  function handleEstadoChange(value: string) {
    setEstado(value)
    resetPage()
  }

  function handleFechaDesdeChange(value: string) {
    setFechaDesde(value)
    resetPage()
  }

  function handleFechaHastaChange(value: string) {
    setFechaHasta(value)
    resetPage()
  }

  function handleExport() {
    if (!data) return
    exportCSV(
      `pedidos-${new Date().toISOString().slice(0, 10)}.csv`,
      ["Número", "Cliente", "Fecha/Hora", "Estado", "Repartidor", "Total"],
      data.data.map((order) => [
        order.numeroPedido,
        order.cliente,
        formatDateTime(order.creadoEn),
        order.estado,
        order.repartidor ?? "",
        order.total,
      ]),
    )
  }

  function FilterField({
    label,
    children,
    icon: Icon,
  }: {
    label: string
    children: ReactNode
    icon?: LucideIcon
  }) {
    return (
      <div className="flex flex-col gap-1">
        <Label className="flex items-center gap-1.5 text-xs text-muted-foreground">
          {Icon ? <Icon className="size-3.5" /> : null}
          {label}
        </Label>
        {children}
      </div>
    )
  }

  const columns: DataColumn<AdminOrderListItem>[] = [
    {
      key: "numeroPedido",
      header: "Pedido",
      render: (order) => (
        <span className="font-medium">{order.numeroPedido}</span>
      ),
    },
    {
      key: "cliente",
      header: "Cliente",
      render: (order) => order.cliente,
    },
    {
      key: "creadoEn",
      header: "Fecha / Hora",
      className: "whitespace-nowrap",
      render: (order) => formatDateTime(order.creadoEn),
    },
    {
      key: "estado",
      header: "Estado",
      render: (order) => <StatusChip status={order.estado} />,
    },
    {
      key: "repartidor",
      header: "Repartidor",
      render: (order) => order.repartidor ?? (
        <span className="text-muted-foreground">Sin asignar</span>
      ),
    },
    {
      key: "total",
      header: "Total",
      className: "text-right tabular-nums",
      render: (order) => formatCurrency(order.total),
    },
    {
      key: "acciones",
      header: "",
      className: "text-right",
      render: (order) => (
        <Button
          variant="ghost"
          size="sm"
          aria-label={`Ver pedido ${order.numeroPedido}`}
          onClick={(event) => {
            event.stopPropagation()
            setSelectedId(order.id)
          }}
        >
          <Eye className="size-4" />
          <span className="sr-only">Ver</span>
        </Button>
      ),
    },
  ]

  if (isError) {
    return (
      <ErrorState
        title="No se pudieron cargar los pedidos"
        description="Revisa tu conexión o intenta nuevamente."
        onRetry={() => void refetch()}
      />
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Pedidos</h1>
          <p className="text-muted-foreground text-sm">
            Administra, asigna y gestiona los pedidos.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            disabled={!data || data.total === 0}
            onClick={handleExport}
          >
            <Download className="size-4" />
            Exportar CSV
          </Button>
          <Button
            variant="outline"
            size="sm"
            disabled={isRefetching}
            onClick={() => void refetch()}
          >
            <RefreshCw className={cn("size-4", isRefetching && "animate-spin")} />
            Actualizar
          </Button>
        </div>
      </div>

      <div className="flex flex-wrap items-end gap-3">
        <FilterField label="Buscar" icon={Search}>
          <Input
            type="search"
            className="w-64"
            placeholder="Número o cliente…"
            value={searchInput}
            onChange={(event) => handleSearchChange(event.target.value)}
          />
        </FilterField>
        <FilterField label="Estado">
          <Select value={estado} onValueChange={handleEstadoChange}>
            <SelectTrigger className="w-44">
              <SelectValue placeholder="Todos los estados" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">Todos los estados</SelectItem>
              {STATUS_FILTERS.map(({ value, label }) => (
                <SelectItem key={value} value={value}>
                  {label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </FilterField>
        <FilterField label="Desde">
          <Input
            type="date"
            className="w-40"
            value={fechaDesde}
            onChange={(event) => handleFechaDesdeChange(event.target.value)}
          />
        </FilterField>
        <FilterField label="Hasta">
          <Input
            type="date"
            className="w-40"
            value={fechaHasta}
            min={fechaDesde || undefined}
            onChange={(event) => handleFechaHastaChange(event.target.value)}
          />
        </FilterField>
      </div>

      {isLoading || !data ? (
        <OrdersLoadingState />
      ) : (
        <DataTable
          columns={columns}
          data={data.data}
          rowKey={(order) => order.id}
          loading={isLoading}
          currentPage={data.page}
          pageSize={data.limit}
          totalItems={data.total}
          onPageChange={setPage}
          onPageSizeChange={(size) => {
            setPageSize(size)
            resetPage()
          }}
          emptyTitle="Sin pedidos"
          emptyDescription="No hay pedidos que coincidan con los filtros seleccionados."
          onRowClick={(order) => setSelectedId(order.id)}
        />
      )}

      <OrderDetailDialog
        orderId={selectedId}
        onOpenChange={(open) => {
          if (!open) setSelectedId(null)
        }}
      />
    </div>
  )
}