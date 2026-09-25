import { useEffect, useState } from "react"
import { toast } from "sonner"
import { Bike, CheckCircle2 } from "lucide-react"
import { cn } from "cn"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { EmptyState } from "@/components/common/empty-state"
import { ErrorState } from "@/components/common/error-state"
import { Skeleton } from "@/components/ui/skeleton"
import {
  useAdminDeliveryPersons,
  useAssignDeliveryPerson,
} from "@/lib/api/admin/orders"
import { getApiErrorMessage } from "@/lib/api/error"

export interface AssignDeliveryDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  orderId: string | null
  orderNumber: string
  currentRepartidor: string | null
}

export function AssignDeliveryDialog({
  open,
  onOpenChange,
  orderId,
  orderNumber,
  currentRepartidor,
}: AssignDeliveryDialogProps) {
  const [selectedId, setSelectedId] = useState("")
  const assign = useAssignDeliveryPerson()

  const { data, isLoading, isError, refetch } = useAdminDeliveryPersons({
    params: { estado: "Disponible", page: 1, limit: 100 },
    enabled: open && Boolean(orderId),
  })

  useEffect(() => {
    if (open) setSelectedId("")
  }, [open])

  async function handleConfirm() {
    if (!orderId || !selectedId) return

    try {
      await assign.mutateAsync({ id: orderId, repartidorId: selectedId })
      toast.success(`Repartidor asignado al pedido ${orderNumber}`)
      onOpenChange(false)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo asignar el repartidor"))
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Bike className="size-5" />
            Asignar repartidor
          </DialogTitle>
          <DialogDescription>
            {currentRepartidor
              ? `Reasignar el pedido ${orderNumber} (actualmente: ${currentRepartidor}).`
              : `Elige un repartidor disponible para el pedido ${orderNumber}.`}
          </DialogDescription>
        </DialogHeader>

        <div className="max-h-72 space-y-2 overflow-y-auto pr-1">
          {isLoading ? (
            <div className="space-y-2">
              {Array.from({ length: 4 }).map((_, i) => (
                <Skeleton key={i} className="h-14" />
              ))}
            </div>
          ) : isError ? (
            <ErrorState
              title="No se pudieron cargar los repartidores"
              onRetry={() => void refetch()}
            />
          ) : data && data.data.length === 0 ? (
            <EmptyState
              title="Sin repartidores disponibles"
              description="Todos los repartidores están ocupados o inactivos."
            />
          ) : (
            data?.data.map((deliveryPerson) => {
              const selected = selectedId === deliveryPerson.usuarioId
              return (
                <button
                  key={deliveryPerson.usuarioId}
                  type="button"
                  className={cn(
                    "flex w-full items-center justify-between gap-3 rounded-md border p-3 text-left transition-colors hover:border-primary/50",
                    selected && "border-primary bg-primary/5",
                  )}
                  onClick={() => setSelectedId(deliveryPerson.usuarioId)}
                >
                  <span className="min-w-0">
                    <span className="block truncate text-sm font-medium">
                      {deliveryPerson.nombre}
                    </span>
                    <span className="block truncate text-xs text-muted-foreground">
                      {deliveryPerson.entregasCompletadas} entregas
                      {deliveryPerson.vehiculo ? ` • ${deliveryPerson.vehiculo}` : ""}
                    </span>
                  </span>
                  {selected ? (
                    <CheckCircle2 className="size-5 shrink-0 text-primary" />
                  ) : null}
                </button>
              )
            })
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" disabled={assign.isPending} onClick={() => onOpenChange(false)}>
            Cancelar
          </Button>
          <Button disabled={!selectedId || assign.isPending} onClick={() => void handleConfirm()}>
            {assign.isPending ? "Asignando…" : "Asignar"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}