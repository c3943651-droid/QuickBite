import { useMemo } from "react"
import {
  Bike,
  CircleCheck,
  Download,
  Gauge,
  RefreshCw,
  type LucideIcon,
} from "lucide-react"
import { cn } from "cn"
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { Button } from "@/components/ui/button"
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
import {
  useDeliveryPerformance,
  type DeliveryPerformanceItem,
} from "@/lib/api/admin/reports"
import { exportCSV } from "@/lib/csv"

function effectiveRate(item: DeliveryPerformanceItem) {
  if (item.pedidosAsignados === 0) return 0
  return (item.entregasCompletadas / item.pedidosAsignados) * 100
}

function handleExport(rows: DeliveryPerformanceItem[]) {
  exportCSV(
    "desempeno-reparto.csv",
    [
      "Repartidor",
      "Pedidos asignados",
      "Entregas completadas",
      "Cancelaciones",
      "Tiempo promedio (min)",
      "Efectividad (%)",
    ],
    rows.map((item) => [
      item.nombre,
      item.pedidosAsignados,
      item.entregasCompletadas,
      item.cancelaciones,
      item.minutosPromedioEntrega,
      effectiveRate(item).toFixed(1),
    ]),
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
      <p className="text-muted-foreground">{payload[0].value} entregas</p>
    </div>
  )
}

function MetricCard({
  title,
  value,
  description,
  icon: Icon,
  accent,
}: {
  title: string
  value: string
  description: string
  icon: LucideIcon
  accent: string
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row">
        <CardTitle className="text-sm font-medium text-muted-foreground">{title}</CardTitle>
        <div
          data-slot="card-action"
          className={cn("flex size-9 items-center justify-center rounded-lg", accent)}
        >
          <Icon className="size-4" />
        </div>
      </CardHeader>
      <CardContent className="pt-2">
        <p className="text-2xl font-semibold tabular-nums">{value}</p>
        <p className="text-muted-foreground text-xs">{description}</p>
      </CardContent>
    </Card>
  )
}

export default function DeliveryPerformanceReportPage() {
  const { data, isLoading, isFetching, isRefetching, isError, refetch } = useDeliveryPerformance()

  const rows = useMemo(() => {
    const items = data ?? []
    if (items.length === 0) return items
    return [...items].sort(
      (a, b) =>
        effectiveRate(b) - effectiveRate(a) ||
        b.entregasCompletadas - a.entregasCompletadas,
    )
  }, [data])

  const totals = useMemo(() => {
    const entregas = rows.reduce((sum, item) => sum + item.entregasCompletadas, 0)
    const asignados = rows.reduce((sum, item) => sum + item.pedidosAsignados, 0)
    const minutos = rows.reduce(
      (sum, item) => sum + item.minutosPromedioEntrega * Math.max(item.entregasCompletadas, 1),
      0,
    )
    const peso = rows.reduce((sum, item) => sum + Math.max(item.entregasCompletadas, 1), 0)
    return {
      entregas,
      tasa: asignados === 0 ? 0 : (entregas / asignados) * 100,
      minutos: peso === 0 ? 0 : minutos / peso,
    }
  }, [rows])

  const chartData = rows.slice(0, 10).map((item) => ({
    name: item.nombre,
    entregas: item.entregasCompletadas,
    completadas: item.entregasCompletadas,
    canceladas: item.cancelaciones,
  }))

  const columns: DataColumn<DeliveryPerformanceItem>[] = [
    {
      key: "nombre",
      header: "Repartidor",
      render: (item) => item.nombre,
    },
    {
      key: "pedidosAsignados",
      header: "Asignados",
      className: "tabular-nums text-right",
      render: (item) => item.pedidosAsignados,
    },
    {
      key: "entregasCompletadas",
      header: "Entregas",
      className: "tabular-nums text-right",
      render: (item) => item.entregasCompletadas,
    },
    {
      key: "cancelaciones",
      header: "Cancelaciones",
      className: "tabular-nums text-right",
      render: (item) => item.cancelaciones,
    },
    {
      key: "minutosPromedioEntrega",
      header: "Tiempo promedio",
      className: "tabular-nums text-right",
      render: (item) => `${item.minutosPromedioEntrega} min`,
    },
    {
      key: "tasaEfectividad",
      header: "Efectividad",
      className: "tabular-nums text-right",
      render: (item) => `${effectiveRate(item).toFixed(1)}%`,
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Desempeño de reparto</h1>
          <p className="text-muted-foreground text-sm">
            Entregas completadas y tiempos promedio por repartidor.
          </p>
        </div>
        <Button
          variant="outline"
          size="sm"
          disabled={isRefetching}
          onClick={() => handleExport(rows)}
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

      {isError ? (
        <ErrorState
          title="No se pudo cargar el reporte"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : (
        <>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <MetricCard
              title="Entregas completadas"
              value={String(totals.entregas)}
              description="Total de entregas realizadas"
              icon={CircleCheck}
              accent="bg-green-100 text-green-700 dark:bg-green-500/15 dark:text-green-300"
            />
            <MetricCard
              title="Tiempo promedio"
              value={`${totals.minutos.toFixed(1)} min`}
              description="Promedio ponderado por repartidor"
              icon={Gauge}
              accent="bg-sky-100 text-sky-700 dark:bg-sky-500/15 dark:text-sky-300"
            />
            <MetricCard
              title="Tasa de efectividad"
              value={`${totals.tasa.toFixed(1)}%`}
              description="Entregas sobre pedidos asignados"
              icon={Bike}
              accent="bg-indigo-100 text-indigo-700 dark:bg-indigo-500/15 dark:text-indigo-300"
            />
          </div>

          <Card>
            <CardHeader>
              <CardTitle>Entregas por repartidor</CardTitle>
              <CardDescription>Repartidores con más entregas completadas.</CardDescription>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="h-64 animate-pulse rounded-lg bg-muted/60" />
              ) : chartData.length === 0 ? (
                <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
                  No hay entregas registradas para mostrar.
                </div>
              ) : (
                <div className="h-64 w-full">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={chartData} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                      <XAxis
                        dataKey="name"
                        tickLine={false}
                        axisLine={false}
                        tick={{ fontSize: 12 }}
                      />
                      <YAxis
                        tickLine={false}
                        axisLine={false}
                        width={36}
                        tick={{ fontSize: 12 }}
                      />
                      <Tooltip content={<BarTooltip />} />
                      <Bar dataKey="entregas" name="Entregas" radius={[4, 4, 0, 0]}>
                        {chartData.map((entry) => (
                          <Cell key={entry.name} fill="var(--chart-2)" />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              )}
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Detalle por repartidor</CardTitle>
              <CardDescription>
                Pedidos asignados, completados y tiempo promedio por entrega.
              </CardDescription>
            </CardHeader>
            <CardContent>
              {isLoading ? (
                <div className="h-48 animate-pulse rounded-lg bg-muted/60" />
              ) : rows.length === 0 ? (
                <EmptyState
                  title="Sin resultados"
                  description="Asigna pedidos a repartidores para ver su desempeño."
                />
              ) : (
                <DataTable
                  columns={columns}
                  data={rows}
                  rowKey={(item) => item.repartidorId}
                  loading={isFetching}
                />
              )}
            </CardContent>
          </Card>
        </>
      )}
    </div>
  )
}