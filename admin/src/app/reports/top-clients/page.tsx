import { Download, RefreshCw } from "lucide-react"
import { cn } from "cn"
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
import { useTopClients, type TopClientItem } from "@/lib/api/admin/reports"
import { exportCSV } from "@/lib/csv"
import { formatCurrency, formatDate } from "@/lib/format"
import { useState } from "react"

const LIMIT_OPTIONS = [10, 20, 50]

export default function TopClientsReportPage() {
  const [limite, setLimite] = useState(10)

  const { data, isLoading, isFetching, isRefetching, isError, refetch } = useTopClients(limite)

  const rows = data ?? []

  function handleExport() {
    exportCSV(
      "clientes-top.csv",
      ["Cliente", "Email", "Pedidos", "Gasto total", "Gasto promedio", "Última compra"],
      rows.map((item) => [
        item.nombre,
        item.email,
        item.totalPedidos,
        item.gastoTotal,
        item.gastoPromedio,
        item.ultimoPedido ? item.ultimoPedido.slice(0, 10) : "—",
      ]),
    )
  }

  const columns: DataColumn<TopClientItem>[] = [
    {
      key: "nombre",
      header: "Cliente",
      render: (item) => item.nombre,
    },
    {
      key: "email",
      header: "Email",
      render: (item) => item.email,
    },
    {
      key: "totalPedidos",
      header: "Pedidos",
      className: "tabular-nums text-right",
      render: (item) => item.totalPedidos,
    },
    {
      key: "gastoTotal",
      header: "Gasto total",
      className: "tabular-nums text-right",
      render: (item) => formatCurrency(item.gastoTotal),
    },
    {
      key: "gastoPromedio",
      header: "Gasto promedio",
      className: "tabular-nums text-right",
      render: (item) => formatCurrency(item.gastoPromedio),
    },
    {
      key: "ultimoPedido",
      header: "Última compra",
      className: "tabular-nums",
      render: (item) => (item.ultimoPedido ? formatDate(item.ultimoPedido) : "—"),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Clientes top</h1>
          <p className="text-muted-foreground text-sm">
            Ranking de clientes por número de pedidos y gasto.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="sm" onClick={handleExport} disabled={rows.length === 0}>
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

      <label className="space-y-1">
        <span className="text-xs font-medium text-muted-foreground">Mostrar</span>
        <Select value={String(limite)} onValueChange={(value) => setLimite(Number(value))}>
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

      <Card>
        <CardHeader>
          <CardTitle>Ranking de clientes</CardTitle>
          <CardDescription>
            Clientes que más compran, ordenados por gasto total.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {isError ? (
            <ErrorState
              title="No se pudo cargar el reporte"
              description="Revisa tu conexión o intenta nuevamente."
              onRetry={() => void refetch()}
            />
          ) : isLoading ? (
            <div className="h-48 animate-pulse rounded-lg bg-muted/60" />
          ) : rows.length === 0 ? (
            <EmptyState
              title="Sin resultados"
              description="Registra pedidos para ver el ranking de clientes."
            />
          ) : (
            <DataTable
              columns={columns}
              data={rows}
              rowKey={(item) => item.clienteId}
              loading={isFetching}
            />
          )}
        </CardContent>
      </Card>
    </div>
  )
}