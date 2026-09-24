import { useEffect, useState } from "react"
import { ChevronLeft, ChevronRight, Clock, Phone } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { StatusChip } from "@/components/common/status-chip"
import { EmptyState } from "@/components/common/empty-state"
import { ErrorState } from "@/components/common/error-state"
import {
  deliveryPersonStatusLabel,
  useDeliveryPersonHistory,
} from "@/lib/api/admin/delivery-persons"
import type { DeliveryPersonListItem } from "@/lib/api/admin/orders"
import { formatCurrency, formatDate, formatDateTime } from "@/lib/format"

export interface DeliveryPersonDetailDialogProps {
  repartidor: DeliveryPersonListItem | null
  onOpenChange: (open: boolean) => void
}

const HISTORY_PAGE_SIZE = 5

function InfoRow({ icon: Icon, label, value }: {
  icon: typeof Phone
  label: string
  value: string
}) {
  return (
    <div className="flex items-start gap-2">
      <Icon className="mt-0.5 size-4 shrink-0 text-muted-foreground" />
      <div className="min-w-0">
        <p className="text-xs font-medium text-muted-foreground">{label}</p>
        <p className="text-sm break-words">{value || "—"}</p>
      </div>
    </div>
  )
}

function formatMinutes(minutes: number): string {
  return `${Math.round(minutes)} min`
}

export function DeliveryPersonDetailDialog({
  repartidor,
  onOpenChange,
}: DeliveryPersonDetailDialogProps) {
  const open = repartidor !== null
  const [page, setPage] = useState(1)

  useEffect(() => {
    setPage(1)
  }, [repartidor?.usuarioId])

  const { data, isLoading, isError, refetch } = useDeliveryPersonHistory(
    repartidor?.usuarioId,
    { page, limit: HISTORY_PAGE_SIZE },
  )

  const totalPages = Math.max(
    1,
    Math.ceil((data?.total ?? 0) / HISTORY_PAGE_SIZE),
  )

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          {repartidor ? (
            <div className="flex flex-wrap items-center gap-3">
              <div className="bg-primary/10 text-primary flex size-10 shrink-0 items-center justify-center rounded-full text-sm font-semibold">
                {initials(repartidor.nombre)}
              </div>
              <div className="min-w-0">
                <DialogTitle className="flex flex-wrap items-center gap-2">
                  {repartidor.nombre}
                  <StatusChip
                    status={deliveryPersonStatusLabel(repartidor.estadoDisponibilidad)}
                  />
                </DialogTitle>
                <p className="text-muted-foreground text-sm">{repartidor.email}</p>
              </div>
            </div>
          ) : (
            <DialogTitle>Repartidor</DialogTitle>
          )}
        </DialogHeader>

        {!repartidor ? null : (
          <div className="space-y-4">
            <section className="grid grid-cols-1 gap-4 rounded-lg border p-4 sm:grid-cols-2">
              <InfoRow icon={Phone} label="Teléfono" value={repartidor.telefono ?? ""} />
              <InfoRow icon={Clock} label="Fecha de alta" value={formatDate(repartidor.fechaAlta)} />
              <InfoRow icon={Phone} label="Vehículo" value={repartidor.vehiculo ?? ""} />
              <InfoRow
                icon={Clock}
                label="Entregas completadas"
                value={String(repartidor.entregasCompletadas)}
              />
            </section>

            <section className="space-y-3 rounded-lg border p-4">
              <h3 className="text-sm font-semibold">Historial de entregas</h3>

              {isLoading ? (
                <div className="space-y-2">
                  {Array.from({ length: 3 }).map((_, index) => (
                    <div key={index} className="h-10 animate-pulse rounded-md bg-muted" />
                  ))}
                </div>
              ) : isError ? (
                <ErrorState
                  title="No se pudo cargar el historial"
                  onRetry={() => void refetch()}
                />
              ) : (data?.data ?? []).length === 0 ? (
                <EmptyState
                  title="Sin entregas registradas"
                  description="Las entregas completadas aparecerán aquí."
                />
              ) : (
                <>
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Pedido</TableHead>
                        <TableHead>Cliente</TableHead>
                        <TableHead className="text-right">Total</TableHead>
                        <TableHead>Entregado</TableHead>
                        <TableHead className="text-right">Tiempo</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {data?.data.map((entry) => (
                        <TableRow key={entry.numeroPedido}>
                          <TableCell className="font-medium">{entry.numeroPedido}</TableCell>
                          <TableCell>{entry.cliente}</TableCell>
                          <TableCell className="text-right tabular-nums">
                            {formatCurrency(entry.total)}
                          </TableCell>
                          <TableCell>
                            {entry.entregadoEn ? (
                              formatDateTime(entry.entregadoEn)
                            ) : (
                              <span className="text-muted-foreground">—</span>
                            )}
                          </TableCell>
                          <TableCell className="text-right tabular-nums">
                            {entry.tiempoEntregaMinutos !== null ? (
                              formatMinutes(entry.tiempoEntregaMinutos)
                            ) : (
                              <span className="text-muted-foreground">—</span>
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>

                  <div className="flex items-center justify-between pt-1 text-sm">
                    <p className="text-muted-foreground">
                      {(data?.total ?? 0) === 0
                        ? "0 registros"
                        : `${(page - 1) * HISTORY_PAGE_SIZE + 1}–${Math.min(
                            page * HISTORY_PAGE_SIZE,
                            data?.total ?? 0,
                          )} de ${data?.total ?? 0} registros`}
                    </p>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={page <= 1}
                        onClick={() => setPage(page - 1)}
                      >
                        <ChevronLeft className="size-4" />
                        Anterior
                      </Button>
                      <span className="text-muted-foreground">
                        {page} / {totalPages}
                      </span>
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={page >= totalPages}
                        onClick={() => setPage(page + 1)}
                      >
                        Siguiente
                        <ChevronRight className="size-4" />
                      </Button>
                    </div>
                  </div>
                </>
              )}
            </section>
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}

function initials(nombre: string): string {
  return nombre
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase()
}