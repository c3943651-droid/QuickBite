import { useMemo, useState } from "react"
import { Download, RefreshCw, ScrollText } from "lucide-react"
import { cn } from "cn"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { EmptyState } from "@/components/common/empty-state"
import { ErrorState } from "@/components/common/error-state"
import { useAuditLog, type AuditEntry } from "@/lib/api/admin/audit"
import { exportCSV } from "@/lib/csv"
import { formatDateTime } from "@/lib/format"

function auditChip(label: string) {
  return (
    <span className="inline-flex shrink-0 items-center gap-1.5 rounded-md bg-muted px-2 py-0.5 text-xs font-medium">
      {label}
    </span>
  )
}

function UserCell({ entry }: { entry: AuditEntry }) {
  if (!entry.usuario) {
    return <span className="text-muted-foreground">Usuario eliminado</span>
  }
  return (
    <div className="flex min-w-0 flex-col">
      <span className="truncate font-medium">{entry.usuario.nombre}</span>
      <span className="truncate text-xs text-muted-foreground">{entry.usuario.email}</span>
    </div>
  )
}

function DetailsCell({ detalles }: { detalles: string | null }) {
  if (!detalles) return <span className="text-muted-foreground">—</span>
  const text = detalles.length > 80 ? `${detalles.slice(0, 80)}…` : detalles
  return (
    <span
      className="block max-w-64 truncate font-mono text-xs"
      title={detalles}
    >
      {text}
    </span>
  )
}

export default function AuditPage() {
  const [desde, setDesde] = useState("")
  const [hasta, setHasta] = useState("")
  const [userQuery, setUserQuery] = useState("")
  const [entidad, setEntidad] = useState("")
  const [accion, setAccion] = useState("")
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [sortKey, setSortKey] = useState("")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc")
  const [detail, setDetail] = useState<AuditEntry | null>(null)

  const { data, isLoading, isFetching, isRefetching, isError, refetch } = useAuditLog()

  const options = useMemo(() => {
    const entities = new Set<string>()
    const actions = new Set<string>()
    for (const entry of data ?? []) {
      entities.add(entry.entidad)
      actions.add(entry.accion)
    }
    return {
      entities: [...entities].sort(),
      actions: [...actions].sort(),
    }
  }, [data])

  const filtered = useMemo(() => {
    const q = userQuery.trim().toLowerCase()
    const items = (data ?? []).filter((entry) => {
      if (desde !== "" && entry.creadoEn.slice(0, 10) < desde) return false
      if (hasta !== "" && entry.creadoEn.slice(0, 10) > hasta) return false
      if (entidad !== "" && entry.entidad !== entidad) return false
      if (accion !== "" && entry.accion !== accion) return false
      if (q !== "") {
        const haystack = `${entry.usuario?.nombre ?? ""} ${entry.usuario?.email ?? ""}`.toLowerCase()
        if (!haystack.includes(q)) return false
      }
      return true
    })
    if (!sortKey) return items
    const dir = sortDir === "asc" ? 1 : -1
    items.sort((a, b) => {
      const av = a[sortKey as keyof AuditEntry]
      const bv = b[sortKey as keyof AuditEntry]
      if (typeof av === "number" && typeof bv === "number") return (av - bv) * dir
      return String(av ?? "").localeCompare(String(bv ?? "")) * dir
    })
    return items
  }, [data, desde, hasta, entidad, accion, userQuery, sortKey, sortDir])

  const total = filtered.length
  const totalPages = Math.max(1, Math.ceil(total / limit))
  const currentPage = Math.min(page, totalPages)
  const tableRows = filtered.slice((currentPage - 1) * limit, currentPage * limit)

  const hasFilters =
    desde !== "" || hasta !== "" || userQuery !== "" || entidad !== "" || accion !== ""

  function handleExport() {
    exportCSV(
      "bitacora-auditoria.csv",
      ["Fecha", "Usuario", "Email", "Acción", "Entidad", "Entidad ID", "IP", "Detalles"],
      filtered.map((entry) => [
        entry.creadoEn,
        entry.usuario?.nombre ?? "",
        entry.usuario?.email ?? "",
        entry.accion,
        entry.entidad,
        entry.entidadId ?? "",
        entry.ipOrigen ?? "",
        entry.detalles ?? "",
      ]),
    )
  }

  function clearFilters() {
    setDesde("")
    setHasta("")
    setUserQuery("")
    setEntidad("")
    setAccion("")
    setPage(1)
  }

  const columns: DataColumn<AuditEntry>[] = [
    {
      key: "creadoEn",
      header: "Fecha / hora",
      sortable: true,
      className: "whitespace-nowrap",
      render: (entry) => formatDateTime(entry.creadoEn),
    },
    {
      key: "usuarioId",
      header: "Usuario",
      render: (entry) => <UserCell entry={entry} />,
    },
    {
      key: "accion",
      header: "Acción",
      sortable: true,
      render: (entry) => auditChip(entry.accion),
    },
    {
      key: "entidad",
      header: "Entidad",
      sortable: true,
      render: (entry) => auditChip(entry.entidad),
    },
    {
      key: "detalles",
      header: "Detalle de cambios",
      render: (entry) => <DetailsCell detalles={entry.detalles} />,
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Auditoría</h1>
          <p className="text-muted-foreground text-sm">
            Bitácora de acciones registradas en el sistema.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={handleExport} disabled={filtered.length === 0}>
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

      <div className="flex flex-wrap items-end gap-2">
        <label className="space-y-1">
          <span className="text-xs font-medium text-muted-foreground">Desde</span>
          <Input
            type="date"
            value={desde}
            onChange={(event) => {
              setDesde(event.target.value)
              setPage(1)
            }}
            className="w-40"
          />
        </label>
        <label className="space-y-1">
          <span className="text-xs font-medium text-muted-foreground">Hasta</span>
          <Input
            type="date"
            value={hasta}
            onChange={(event) => {
              setHasta(event.target.value)
              setPage(1)
            }}
            className="w-40"
          />
        </label>
        <label className="space-y-1">
          <span className="text-xs font-medium text-muted-foreground">Buscar usuario</span>
          <Input
            placeholder="Nombre o email"
            value={userQuery}
            onChange={(event) => {
              setUserQuery(event.target.value)
              setPage(1)
            }}
            className="w-56"
          />
        </label>
        <label className="space-y-1">
          <span className="text-xs font-medium text-muted-foreground">Entidad</span>
          <Select
            value={entidad}
            onValueChange={(value) => {
              setEntidad(value)
              setPage(1)
            }}
          >
            <SelectTrigger className="w-40">
              <SelectValue placeholder="Todas" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="">Todas</SelectItem>
              {options.entities.map((value) => (
                <SelectItem key={value} value={value}>
                  {value}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </label>
        <label className="space-y-1">
          <span className="text-xs font-medium text-muted-foreground">Acción</span>
          <Select
            value={accion}
            onValueChange={(value) => {
              setAccion(value)
              setPage(1)
            }}
          >
            <SelectTrigger className="w-40">
              <SelectValue placeholder="Todas" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="">Todas</SelectItem>
              {options.actions.map((value) => (
                <SelectItem key={value} value={value}>
                  {value}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </label>
        {hasFilters ? (
          <Button variant="ghost" size="sm" onClick={clearFilters}>
            Limpiar filtros
          </Button>
        ) : null}
      </div>

      {isError ? (
        <ErrorState
          title="No se pudo cargar la bitácora"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : (
        <Card>
          <CardHeader>
            <CardTitle>Bitácora</CardTitle>
            <CardDescription>
              Haz clic en un registro para ver el detalle completo.
            </CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="h-48 animate-pulse rounded-lg bg-muted/60" />
            ) : total === 0 ? (
              <EmptyState
                title="Sin registros"
                description="Ajusta los filtros o regresa más tarde."
              />
            ) : (
              <DataTable
                columns={columns}
                data={tableRows}
                rowKey={(entry) => entry.id}
                loading={isFetching}
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
                onRowClick={setDetail}
              />
            )}
          </CardContent>
        </Card>
      )}

      <Dialog open={detail !== null} onOpenChange={(open) => !open && setDetail(null)}>
        <DialogContent className="sm:max-w-lg">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <ScrollText className="size-4" />
              Detalle de auditoría
            </DialogTitle>
            <DialogDescription>Registro completo de la acción ejecutada.</DialogDescription>
          </DialogHeader>
          {detail ? (
            <div className="space-y-3 text-sm">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <p className="text-xs font-medium text-muted-foreground">Acción</p>
                  <p>{auditChip(detail.accion)}</p>
                </div>
                <div>
                  <p className="text-xs font-medium text-muted-foreground">Entidad</p>
                  <p>{auditChip(detail.entidad)}</p>
                </div>
                <div>
                  <p className="text-xs font-medium text-muted-foreground">Fecha</p>
                  <p>{formatDateTime(detail.creadoEn)}</p>
                </div>
                <div>
                  <p className="text-xs font-medium text-muted-foreground">Usuario</p>
                  <p>
                    {detail.usuario
                      ? `${detail.usuario.nombre} · ${detail.usuario.email}`
                      : "Usuario eliminado"}
                  </p>
                </div>
                <div>
                  <p className="text-xs font-medium text-muted-foreground">IP de origen</p>
                  <p>{detail.ipOrigen ?? "—"}</p>
                </div>
                <div>
                  <p className="text-xs font-medium text-muted-foreground">User agent</p>
                  <p className="truncate" title={detail.userAgent ?? undefined}>
                    {detail.userAgent ?? "—"}
                  </p>
                </div>
              </div>
              <div>
                <p className="text-xs font-medium text-muted-foreground">Detalle de cambios</p>
                <pre className="mt-1 max-h-56 overflow-auto rounded-md border bg-muted/40 p-3 font-mono text-xs whitespace-pre-wrap">
                  {detail.detalles ?? "—"}
                </pre>
              </div>
            </div>
          ) : null}
        </DialogContent>
      </Dialog>
    </div>
  )
}