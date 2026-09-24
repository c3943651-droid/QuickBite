import { useMemo, useState } from "react"
import { Download, RefreshCw } from "lucide-react"
import { cn } from "cn"
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { Button } from "@/components/ui/button"
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
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { EmptyState } from "@/components/common/empty-state"
import { ErrorState } from "@/components/common/error-state"
import { useTopProducts, type TopProductItem } from "@/lib/api/admin/reports"
import { exportCSV } from "@/lib/csv"
import { formatCurrency } from "@/lib/format"

const LIMIT_OPTIONS = [10, 20, 50]

const CHART_COLORS = ["var(--chart-1)", "var(--chart-2)", "var(--chart-3)", "var(--chart-4)", "var(--chart-5)"]

function DonutTooltip({
  active,
  payload,
}: {
  active?: boolean
  payload?: Array<{ name?: string; value: number }>
}) {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-md border bg-background px-3 py-1.5 text-sm shadow-md">
      <p className="font-medium">{payload[0].name}</p>
      <p className="text-muted-foreground">{formatCurrency(payload[0].value)}</p>
    </div>
  )
}

function BarTooltip({
  active,
  payload,
}: {
  active?: boolean
  payload?: Array<{ name?: string; value: number }>
}) {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-md border bg-background px-3 py-1.5 text-sm shadow-md">
      <p className="font-medium">{payload[0].name}</p>
      <p className="text-muted-foreground">{formatCurrency(payload[0].value)}</p>
    </div>
  )
}

export default function TopProductsReportPage() {
  const [limite, setLimite] = useState(10)
  const [sortKey, setSortKey] = useState("")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc")

  const { data, isLoading, isFetching, isRefetching, isError, refetch } = useTopProducts(limite)

  const rows = useMemo(() => {
    const items = [...(data ?? [])]
    if (!sortKey) return items
    const dir = sortDir === "asc" ? 1 : -1
    items.sort((a, b) => {
      const av = a[sortKey as keyof TopProductItem]
      const bv = b[sortKey as keyof TopProductItem]
      if (typeof av === "number" && typeof bv === "number") return (av - bv) * dir
      return String(av ?? "").localeCompare(String(bv ?? "")) * dir
    })
    return items
  }, [data, sortKey, sortDir])

  const tableRows = rows.slice(0, limite)

  const chartData = rows.slice(0, limite).map((item) => ({
    name: item.nombreProducto,
    ingresos: item.ingresosGenerados,
  }))

  function handleExport() {
    exportCSV(
      "productos-mas-vendidos.csv",
      ["Producto", "Unidades vendidas", "Pedidos", "Ingresos"],
      rows.slice(0, limite).map((item) => [
        item.nombreProducto,
        item.unidadesVendidas,
        item.numeroPedidos,
        item.ingresosGenerados,
      ]),
    )
  }

  const columns: DataColumn<TopProductItem>[] = [
    {
      key: "nombreProducto",
      header: "Producto",
      sortable: true,
      render: (item) => item.nombreProducto,
    },
    {
      key: "unidadesVendidas",
      header: "Unidades",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => item.unidadesVendidas,
    },
    {
      key: "numeroPedidos",
      header: "Pedidos",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => item.numeroPedidos,
    },
    {
      key: "ingresosGenerados",
      header: "Ingresos",
      sortable: true,
      className: "tabular-nums text-right",
      render: (item) => formatCurrency(item.ingresosGenerados),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Productos más vendidos</h1>
          <p className="text-muted-foreground text-sm">
            Ranking de productos por unidades vendidas e ingresos.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={handleExport} disabled={tableRows.length === 0}>
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

      <div className="flex items-center gap-2">
        <label className="space-y-1">
          <span className="text-xs font-medium text-muted-foreground">Mostrar</span>
          <Select
            value={String(limite)}
            onValueChange={(value) => setLimite(Number(value))}
          >
            <SelectTrigger className="w-28">
              <SelectValue placeholder="Top 10" />
            </SelectTrigger>
            <SelectContent>
              {LIMIT_OPTIONS.map((option) => (
                <SelectItem key={option} value={String(option)}>
                  Top {option}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </label>
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
              <CardTitle>Ingresos por producto</CardTitle>
              <CardDescription>
                Top {limite} productos por facturación.
              </CardDescription>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="h-80 animate-pulse rounded-lg bg-muted/60" />
              ) : chartData.length === 0 ? (
                <div className="flex h-80 items-center justify-center text-sm text-muted-foreground">
                  No hay productos con ventas para mostrar.
                </div>
              ) : (
                <div className="grid grid-cols-1 gap-6 xl:grid-cols-2">
                  <div className="h-80 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <BarChart data={chartData} margin={{ top: 8, right: 8, bottom: 0, left: 0 }} layout="vertical">
                        <CartesianGrid strokeDasharray="3 3" className="stroke-border" horizontal={false} />
                        <XAxis
                          type="number"
                          tickLine={false}
                          axisLine={false}
                          tick={{ fontSize: 12 }}
                          tickFormatter={(value: number) => `$${value}`}
                        />
                        <YAxis
                          type="category"
                          dataKey="name"
                          tickLine={false}
                          axisLine={false}
                          width={140}
                          tick={{ fontSize: 12 }}
                        />
                        <Tooltip content={<BarTooltip />} />
                        <Bar dataKey="ingresos" name="Ingresos" fill="var(--chart-2)" radius={[0, 4, 4, 0]} />
                      </BarChart>
                    </ResponsiveContainer>
                  </div>
                  <div className="h-80 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie
                          data={chartData}
                          dataKey="ingresos"
                          nameKey="name"
                          innerRadius={70}
                          outerRadius={110}
                          paddingAngle={2}
                        >
                          {chartData.map((entry) => (
                            <Cell key={entry.name} fill={CHART_COLORS[chartData.indexOf(entry) % CHART_COLORS.length]} />
                          ))}
                        </Pie>
                        <Tooltip content={<DonutTooltip />} />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Detalle</CardTitle>
              <CardDescription>
                Unidades vendidas, pedidos e ingresos por producto.
              </CardDescription>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="h-48 animate-pulse rounded-lg bg-muted/60" />
              ) : tableRows.length === 0 ? (
                <EmptyState
                  title="Sin resultados"
                  description="Registra ventas de productos para ver el ranking."
                />
              ) : (
                <DataTable
                  columns={columns}
                  data={tableRows}
                  rowKey={(item) => item.productoId}
                  loading={isFetching}
                  sortKey={sortKey}
                  sortDir={sortDir}
                  onSortChange={(key, dir) => {
                    setSortKey(key)
                    setSortDir(dir)
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