import { Link, useNavigate } from "react-router-dom"
import {
  ArrowRight,
  CircleDollarSign,
  ClipboardList,
  RefreshCw,
  Truck,
  type LucideIcon,
} from "lucide-react"
import { cn } from "cn"
import {
  CartesianGrid,
  Line,
  LineChart,
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
import { EmptyState } from "@/components/common/empty-state"
import { ErrorState } from "@/components/common/error-state"
import { StatusChip } from "@/components/common/status-chip"
import { useAdminDashboard } from "@/lib/api/admin/dashboard"
import { formatCurrency, formatDateTime, formatShortDay } from "@/lib/format"

function MetricCard({
  title,
  value,
  description,
  icon: Icon,
  accent = "bg-primary/10 text-primary",
}: {
  title: string
  value: string
  description?: string
  icon: LucideIcon
  accent?: string
}) {
  return (
    <Card>
      <CardHeader className="flex flex-row">
        <CardTitle className="text-sm font-medium text-muted-foreground">
          {title}
        </CardTitle>
        <div
          data-slot="card-action"
          className={cn("flex size-9 items-center justify-center rounded-lg", accent)}
        >
          <Icon className="size-4" />
        </div>
      </CardHeader>
      <CardContent className="pt-2">
        <p className="text-2xl font-semibold tabular-nums">{value}</p>
        {description ? (
          <p className="text-muted-foreground text-xs">{description}</p>
        ) : null}
      </CardContent>
    </Card>
  )
}

function MetricSkeleton() {
  return (
    <Card>
      <CardHeader className="flex flex-row">
        <div className="h-4 w-24 animate-pulse rounded bg-muted" />
        <div
          data-slot="card-action"
          className="size-9 animate-pulse rounded-lg bg-muted"
        />
      </CardHeader>
      <CardContent className="pt-2">
        <div className="h-7 w-32 animate-pulse rounded bg-muted" />
        <div className="mt-1 h-4 w-24 animate-pulse rounded bg-muted" />
      </CardContent>
    </Card>
  )
}

function ChartTooltip({
  active,
  payload,
}: {
  active?: boolean
  payload?: Array<{ value: number }>
}) {
  if (!active || !payload?.length) return null
  return (
    <div className="rounded-md border bg-background px-3 py-1.5 text-sm shadow-md">
      {formatCurrency(payload[0].value)}
    </div>
  )
}

export default function DashboardPage() {
  const navigate = useNavigate()
  const { data, isLoading, isError, isFetching, refetch, isRefetching } = useAdminDashboard()

  if (isError) {
    return (
      <ErrorState
        title="No se pudo cargar el dashboard"
        description="Revisa tu conexión o intenta nuevamente."
        onRetry={() => void refetch()}
      />
    )
  }

  if (isLoading || !data) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <MetricSkeleton />
          <MetricSkeleton />
          <MetricSkeleton />
          <MetricSkeleton />
        </div>
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
          <Card className="xl:col-span-2">
            <div className="h-80 animate-pulse rounded-lg bg-muted/60" />
          </Card>
          <Card>
            <div className="h-80 animate-pulse rounded-lg bg-muted/60" />
          </Card>
        </div>
      </div>
    )
  }

  const chartData = [...data.salesChart]
    .sort((a, b) => a.dia.localeCompare(b.dia))
    .slice(-7)
    .map((item) => ({ ...item, label: formatShortDay(item.dia) }))

  const lastOrders = [...data.recentOrders]
    .sort((a, b) => new Date(b.fecha).getTime() - new Date(a.fecha).getTime())
    .slice(0, 5)

  const empty = data.totalPedidos === 0 && data.recentOrders.length === 0

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-semibold">Dashboard</h1>
          <p className="text-muted-foreground text-sm">
            Resumen del estado actual del negocio.
          </p>
        </div>
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

      {isFetching ? (
        <p className="text-muted-foreground text-xs">Actualizando…</p>
      ) : null}

      {empty ? (
        <EmptyState
          title="Sin actividad todavía"
          description="Aún no hay pedidos. Cuando lleguen los primeros pedidos verás aquí las métricas del negocio."
        />
      ) : (
        <div className="space-y-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <MetricCard
              title="Pedidos hoy"
              value={String(data.totalPedidos)}
              description="Pedidos registrados en el día"
              icon={ClipboardList}
              accent="bg-sky-100 text-sky-700 dark:bg-sky-500/15 dark:text-sky-300"
            />
            <MetricCard
              title="Ingresos del día"
              value={formatCurrency(data.ventasTotales)}
              description="Suma de todas las ventas"
              icon={CircleDollarSign}
              accent="bg-green-100 text-green-700 dark:bg-green-500/15 dark:text-green-300"
            />
            <MetricCard
              title="Pedidos activos"
              value={String(data.pendientes)}
              description="Pendientes de atención"
              icon={ClipboardList}
              accent="bg-amber-100 text-amber-700 dark:bg-amber-500/15 dark:text-amber-300"
            />
            <MetricCard
              title="En camino"
              value={String(data.porEstado.EnCamino ?? data.porEstado["en camino"] ?? 0)}
              description="Pedidos en reparto"
              icon={Truck}
              accent="bg-indigo-100 text-indigo-700 dark:bg-indigo-500/15 dark:text-indigo-300"
            />
          </div>

          <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
            <Card className="xl:col-span-2">
              <CardHeader>
                <CardTitle>Ventas últimos 7 días</CardTitle>
                <CardDescription>Evolución diaria de los ingresos.</CardDescription>
              </CardHeader>
              <CardContent>
                {chartData.length === 0 ? (
                  <div className="flex h-64 items-center justify-center text-sm text-muted-foreground">
                    No hay datos de ventas para mostrar.
                  </div>
                ) : (
                  <div className="h-64 w-full">
                    <ResponsiveContainer width="100%" height="100%">
                      <LineChart data={chartData} margin={{ top: 8, right: 8, bottom: 0, left: 8 }}>
                        <CartesianGrid strokeDasharray="3 3" className="stroke-border" />
                        <XAxis
                          dataKey="label"
                          tickLine={false}
                          axisLine={false}
                          tick={{ fontSize: 12 }}
                        />
                        <YAxis
                          tickLine={false}
                          axisLine={false}
                          width={48}
                          tick={{ fontSize: 12 }}
                          tickFormatter={(value: number) => `$${value}`}
                        />
                        <Tooltip content={<ChartTooltip />} />
                        <Line
                          type="monotone"
                          dataKey="ventas"
                          stroke="var(--chart-1)"
                          strokeWidth={2}
                          dot={{ r: 3 }}
                          activeDot={{ r: 5 }}
                        />
                      </LineChart>
                    </ResponsiveContainer>
                  </div>
                )}
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Últimos pedidos</CardTitle>
                <CardDescription>Los 5 más recientes.</CardDescription>
              </CardHeader>
              <CardContent>
                {lastOrders.length === 0 ? (
                  <p className="text-muted-foreground text-sm">
                    Sin pedidos recientes.
                  </p>
                ) : (
                  <div className="space-y-3">
                    {lastOrders.map((order) => (
                      <button
                        key={order.id}
                        type="button"
                        onClick={() => navigate("/orders")}
                        className="flex w-full flex-col gap-1 rounded-md border p-3 text-left transition-colors hover:bg-accent/50"
                      >
                        <div className="flex items-center justify-between gap-2">
                          <span className="font-medium">{order.numeroPedido}</span>
                          <StatusChip status={order.estado} />
                        </div>
                        <span className="text-sm">{order.cliente}</span>
                        <div className="flex items-center justify-between text-xs text-muted-foreground">
                          <span>{formatCurrency(order.total)}</span>
                          <span>{formatDateTime(order.fecha)}</span>
                        </div>
                      </button>
                    ))}
                    <Button asChild variant="ghost" className="w-full">
                      <Link to="/orders">
                        Ver todos
                        <ArrowRight className="size-4" />
                      </Link>
                    </Button>
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      )}
    </div>
  )
}