import { useMemo, useState } from "react"
import { Download, RefreshCw } from "lucide-react"
import { cn } from "cn"
import {
  Bar,
  CartesianGrid,
  ComposedChart,
  Legend,
  Line,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { EmptyState } from "@/components/common/empty-state"
import { ErrorState } from "@/components/common/error-state"
import { useSalesByDay, type SalesByDayItem } from "@/lib/api/admin/reports"
import { exportCSV } from "@/lib/csv"
import { formatCurrency, formatDate, formatShortDay } from "@/lib/format"

function ChartTooltip({
  active,
  payload,
}: {
  active?: boolean
  payload?: Array<{ dataKey: string; value: number }>
}) {
  if (!active || !payload?.length) return null
  const ingresos = payload.find((entry) => entry.dataKey === "ingresos")?.value ?? 0
  const pedidos = payload.find((entry) => entry.dataKey === "totalPedidos")?.value ?? 0
  return (
    <div className="space-y-1 rounded-md border bg-background px-3 py-1.5 text-sm shadow-md">
      <p className="font-medium">{formatCurrency(ingresos)}</p>
      <p className="text-muted-foreground">{pedidos} pedidos</p>
    </div>
  )
}

export default function SalesByDayReportPage() {
  const [desde, setDesde] = useState("")
  const [hasta, setHasta] = useState("")
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [sortKey, setSortKey] = useState("")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc")

  const { data, isLoading, isFetching, isRefetching, isError, refetch } = useSalesByDay(
    desde || undefined,
    hasta || undefined,
  )

  const rows = useMemo(() => {
    const items = [...(data ?? [])].sort((a, b) => a.dia.localeCompare(b.dia))
    if (!sortKey) return items
    const dir = sortDir === "asc" ? 1 : -1
    items.sort((a, b) => {
      const av = a[sortKey as keyof SalesByDayItem]
      const bv = b[sortKey as keyof SalesByDayItem]
      if (typeof av === "number" && typeof bv === "number") return (av - bv) * dir
      return String(av ?? "").localeCompare(String(bv ?? "")) * dir
    })
    return items
  }, [data, sortKey, sortDir])

  const total = rows.length
  const totalPages = Math.max(1, Math.ceil(total / limit))
  const currentPage = Math.min(page, totalPages)
  const tableRows = rows.slice((currentPage - 1) * limit, currentPage * limit)

  const chartData = rows.map((item) => ({
    ...item,
    label: formatShortDay(item.dia),
  }))

  const hasFilters = desde !== "" || hasta !== ""

  function handleExport() {
    exportCSV(
      "ventas-por-dia.csv",
      [
        "Día",
        "Pedidos",
        "Entregados",
        "Cancelados",
        "Activos",
        "Ingresos",
        "Ticket promedio",
      ],
      rows.map((item) => [
        item.dia,
        item.totalPedidos,
        item.entregados,
        item.cancelados,
        item.activos,
        item.ingresos,
        item.ticketPromedio,
      ]),
    )
  }

  const columns: DataColumn<SalesByDayItem>[] = [
    {
      key: "dia",
      header: "Día",
      sortable: true,
      render: (item) => formatDate(item.dia),
    },
    {
      key: "totalPedidos",
      header: "Pedidos",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => item.totalPedidos,
    },
    {
      key: "entregados",
      header: "Entregados",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => item.entregados,
    },
    {
      key: "cancelados",
      header: "Cancelados",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => item.cancelados,
    },
    {
      key: "activos",
      header: "Activos",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => item.activos,
    },
    {
      key: "ingresos",
      header: "Ingresos",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => formatCurrency(item.ingresos),
    },
    {
      key: "ticketPromedio",
      header: "Ticket promedio",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => formatCurrency(item.ticketPromedio),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Ventas por día</h1>
          <p className="text-muted-foreground text-sm">
            Ingresos y pedidos agrupados por día.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={handleExport} disabled={total === 0}>
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
        {hasFilters ? (
          <Button
            variant="ghost"
            size="sm"
            onClick={() => {
              setDesde("")
              setHasta("")
              setPage(1)
            }}
          >
            Limpiar filtros
          </Button>
        ) : null}
      </div>

      {isError ? (
        <ErrorState
          title="No se pudo cargar el reporte"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : (
        <div className="space-y-6">
          <Card>
            <CardHeader>
              <CardTitle>Ingresos y pedidos</CardTitle>
              <CardDescription>
                Evolución diaria de los ingresos y volumen de pedidos.
              </CardDescription>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="h-64 animate-pulse rounded-lg bg-muted/60" />
              ) : chartData.length === 0 ? (
                <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
                  No hay datos para el rango seleccionado.
                </div>
              ) : (
                <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <ComposedChart data={chartData} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                      <XAxis
                        dataKey="label"
                        tickLine={false}
                        axisLine={false}
                        tick={{ fontSize: 12 }}
                      />
                      <YAxis
                        yAxisId="ingresos"
                        tickLine={false}
                        axisLine={false}
                        width={56}
                        tick={{ fontSize: 12 }}
                        tickFormatter={(value: number) => `$${value}`}
                      />
                      <YAxis
                        yAxisId="pedidos"
                        orientation="right"
                        tickLine={false}
                        axisLine={false}
                        width={36}
                        tick={{ fontSize: 12 }}
                      />
                      <Tooltip content={<ChartTooltip />} />
                      <Legend wrapperStyle={{ fontSize: 12 }} />
                      <Bar
                        yAxisId="ingresos"
                        dataKey="ingresos"
                        name="Ingresos"
                        fill="var(--chart-1)"
                        radius={[4, 4, 0, 0]}
                      />
                      <Line
                        yAxisId="pedidos"
                        type="monotone"
                        dataKey="totalPedidos"
                        name="Pedidos"
                        stroke="var(--chart-2)"
                        strokeWidth={2}
                        dot={{ r: 3 }}
                      />
                    </ComposedChart>
                  </ResponsiveContainer>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Detalle por día</CardTitle>
              <CardDescription>
                Resumen diario con pedidos, cancelaciones e ingresos.
              </CardDescription>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="h-48 animate-pulse rounded-lg bg-muted/60" />
              ) : total === 0 ? (
                <EmptyState
                  title="Sin resultados"
                  description="Ajusta el rango de fechas o registra pedidos para ver el detalle."
                />
              ) : (
                <DataTable
                  columns={columns}
                  data={tableRows}
                  rowKey={(item) => item.dia}
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
                />
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}