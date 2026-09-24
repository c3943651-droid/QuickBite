import { useState } from "react"
import { toast } from "sonner"
import {
  Bike,
  Clock,
  Mail,
  MapPin,
  Phone,
  UserRound,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Separator } from "@/components/ui/separator"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { StatusChip } from "@/components/common/status-chip"
import { ErrorState } from "@/components/common/error-state"
import { CancelOrderDialog } from "@/components/features/orders/cancel-order-dialog"
import { AssignDeliveryDialog } from "@/components/features/orders/assign-delivery-dialog"
import { getNextTransition, isTerminal } from "@/components/features/orders/status-transitions"
import {
  useAdminOrderDetail,
  useUpdateOrderStatus,
} from "@/lib/api/admin/orders"
import { getApiErrorMessage } from "@/lib/api/error"
import { formatCurrency, formatDateTime } from "@/lib/format"

export interface OrderDetailDialogProps {
  orderId: string | null
  onOpenChange: (open: boolean) => void
}

function InfoRow({ icon: Icon, label, value }: {
  icon: typeof UserRound
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

export function OrderDetailDialog({ orderId, onOpenChange }: OrderDetailDialogProps) {
  const open = orderId !== null
  const { data, isLoading, isError, refetch } = useAdminOrderDetail(orderId)
  const updateStatus = useUpdateOrderStatus()
  const [showCancel, setShowCancel] = useState(false)
  const [showAssign, setShowAssign] = useState(false)

  const order = data

  async function handleNextStatus() {
    if (!order) return
    const transition = getNextTransition(order.estado)
    if (!transition) return

    if (order.estado === "Listo" && !order.repartidorNombre) {
      toast.info("Asigna un repartidor antes de enviar el pedido a reparto")
      setShowAssign(true)
      return
    }

    try {
      await updateStatus.mutateAsync({ id: order.id, estado: transition.value })
      toast.success(`Pedido ${order.numeroPedido}: ${transition.label}`)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo actualizar el estado"))
    }
  }

  const next = order ? getNextTransition(order.estado) : undefined
  const terminal = order ? isTerminal(order.estado) : true

  return (
    <>
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-3xl">
          <DialogHeader className="flex flex-row items-start justify-between gap-3">
            <div className="space-y-1">
              {order ? (
                <>
                  <DialogTitle className="flex items-center gap-2">
                    Pedido {order.numeroPedido}
                    <StatusChip status={order.estado} />
                  </DialogTitle>
                  <p className="text-sm text-muted-foreground">
                    Creado el {formatDateTime(order.creadoEn)}
                  </p>
                </>
              ) : (
                <DialogTitle>Cargando pedido…</DialogTitle>
              )}
            </div>
          </DialogHeader>

          {isLoading ? (
            <div className="space-y-4">
              <div className="h-32 animate-pulse rounded-lg bg-muted/60" />
              <div className="h-48 animate-pulse rounded-lg bg-muted/60" />
            </div>
          ) : isError || !order ? (
            <ErrorState
              title="No se pudo cargar el pedido"
              description="Intenta nuevamente."
              onRetry={() => void refetch()}
            />
          ) : (
            <div className="space-y-6">
              {!terminal ? (
                <div className="flex flex-wrap gap-2">
                  {next ? (
                    <Button onClick={() => void handleNextStatus()} disabled={updateStatus.isPending}>
                      {updateStatus.isPending ? "Procesando…" : next.label}
                    </Button>
                  ) : null}
                  {order.estado !== "Cancelado" ? (
                    <Button
                      variant="outline"
                      onClick={() => setShowAssign(true)}
                      disabled={updateStatus.isPending}
                    >
                      <Bike className="size-4" />
                      {order.repartidorNombre ? "Reasignar repartidor" : "Asignar repartidor"}
                    </Button>
                  ) : null}
                  <Button
                    variant="destructive"
                    onClick={() => setShowCancel(true)}
                    disabled={updateStatus.isPending}
                  >
                    Cancelar pedido
                  </Button>
                </div>
              ) : null}

              <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                <CardSection title="Cliente">
                  <InfoRow icon={UserRound} label="Nombre" value={order.clienteNombre} />
                  {order.clienteTelefono ? (
                    <InfoRow icon={Phone} label="Teléfono" value={order.clienteTelefono} />
                  ) : null}
                  {order.clienteEmail ? (
                    <InfoRow icon={Mail} label="Email" value={order.clienteEmail} />
                  ) : null}
                </CardSection>
                <CardSection title="Entrega">
                  <InfoRow icon={MapPin} label="Dirección" value={order.direccionEntregaSnapshot} />
                  {order.repartidorNombre ? (
                    <InfoRow icon={Bike} label="Repartidor" value={order.repartidorNombre} />
                  ) : null}
                  {order.repartidorTelefono ? (
                    <InfoRow icon={Phone} label="Tel. repartidor" value={order.repartidorTelefono} />
                  ) : null}
                </CardSection>
              </div>

              {order.motivoCancelacion ? (
                <div className="rounded-md border border-destructive/40 bg-destructive/5 p-3 text-sm">
                  <span className="font-medium text-destructive">Motivo de cancelación: </span>
                  {order.motivoCancelacion}
                </div>
              ) : null}

              <CardSection title={`Productos (${order.items.length})`}>
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Producto</TableHead>
                      <TableHead className="text-right">Precio</TableHead>
                      <TableHead className="text-right">Cant.</TableHead>
                      <TableHead className="text-right">Subtotal</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {order.items.map((item) => (
                      <TableRow key={item.id}>
                        <TableCell>
                          <span className="font-medium">{item.nombreProducto}</span>
                          {item.opciones.length > 0 ? (
                            <span className="text-muted-foreground block text-xs">
                              {item.opciones
                                .map((opcion) => `+ ${opcion.nombre} (${formatCurrency(opcion.precioAdicional)})`)
                                .join(", ")}
                            </span>
                          ) : null}
                          {item.observaciones ? (
                            <span className="text-muted-foreground block text-xs italic">
                              Nota: {item.observaciones}
                            </span>
                          ) : null}
                        </TableCell>
                        <TableCell className="text-right tabular-nums">
                          {formatCurrency(item.precioUnitario)}
                        </TableCell>
                        <TableCell className="text-right tabular-nums">{item.cantidad}</TableCell>
                        <TableCell className="text-right font-medium tabular-nums">
                          {formatCurrency(item.subtotal)}
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                <div className="flex flex-col gap-1 pt-3 text-sm sm:ml-auto sm:w-56">
                  <div className="flex justify-between text-muted-foreground">
                    <span>Subtotal</span>
                    <span className="tabular-nums">{formatCurrency(order.subtotal)}</span>
                  </div>
                  <div className="flex justify-between text-muted-foreground">
                    <span>Envío</span>
                    <span className="tabular-nums">{formatCurrency(order.costoEnvio)}</span>
                  </div>
                  <Separator />
                  <div className="flex justify-between text-base font-semibold">
                    <span>Total</span>
                    <span className="tabular-nums">{formatCurrency(order.total)}</span>
                  </div>
                </div>
              </CardSection>

              <CardSection title="Historial de estados">
                {order.historialEstados.length === 0 ? (
                  <p className="text-sm text-muted-foreground">Sin cambios registrados.</p>
                ) : (
                  <ol className="space-y-4">
                    {order.historialEstados.map((entry, index) => (
                      <li key={entry.id} className="relative flex gap-3 pl-6">
                        <span
                          className="bg-border absolute top-1.5 left-0 flex size-3 items-center justify-center rounded-full ring-4 ring-background"
                          aria-hidden="true"
                        />
                        {index < order.historialEstados.length - 1 ? (
                          <span
                            className="bg-border absolute top-6 bottom-[-16px] left-[5px] w-px"
                            aria-hidden="true"
                          />
                        ) : null}
                        <div className="min-w-0">
                          <div className="flex flex-wrap items-center gap-2">
                            <StatusChip status={entry.estadoNuevo} />
                            <span className="text-xs text-muted-foreground">
                              {formatDateTime(entry.creadoEn)}
                            </span>
                          </div>
                          <p className="mt-0.5 text-sm">
                            {entry.estadoAnterior
                              ? `Cambió de ${entry.estadoAnterior} a ${entry.estadoNuevo}`
                              : `Pedido ${entry.estadoNuevo}`}
                            {entry.usuario ? ` por ${entry.usuario}` : ""}
                          </p>
                          {entry.comentario ? (
                            <p className="text-muted-foreground text-xs italic">
                              {entry.comentario}
                            </p>
                          ) : null}
                        </div>
                      </li>
                    ))}
                  </ol>
                )}
              </CardSection>

              {order.auditoria.length > 0 ? (
                <CardSection title="Auditoría">
                  <ul className="space-y-2">
                    {order.auditoria.map((entry) => (
                      <li key={entry.id}>
                        <div className="flex flex-wrap items-center gap-2 text-sm">
                          <Clock className="size-3.5 text-muted-foreground" />
                          <span className="text-xs text-muted-foreground">
                            {formatDateTime(entry.creadoEn)}
                          </span>
                          <span className="font-medium">{entry.accion}</span>
                          {entry.usuario ? (
                            <span className="text-muted-foreground">por {entry.usuario}</span>
                          ) : null}
                        </div>
                        {entry.detalles ? (
                          <p className="text-muted-foreground pl-3.5 text-xs">{entry.detalles}</p>
                        ) : null}
                      </li>
                    ))}
                  </ul>
                </CardSection>
              ) : null}
            </div>
          )}
        </DialogContent>
      </Dialog>

      {order ? (
        <>
          <CancelOrderDialog
            open={showCancel}
            onOpenChange={setShowCancel}
            order={{ id: order.id, numeroPedido: order.numeroPedido }}
          />
          <AssignDeliveryDialog
            open={showAssign}
            onOpenChange={setShowAssign}
            orderId={order.id}
            orderNumber={order.numeroPedido}
            currentRepartidor={order.repartidorNombre}
          />
        </>
      ) : null}
    </>
  )
}

function CardSection({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section className="space-y-3 rounded-lg border p-4">
      <h3 className="text-sm font-semibold">{title}</h3>
      {children}
    </section>
  )
}