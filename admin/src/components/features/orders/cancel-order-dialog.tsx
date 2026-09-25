import { useState } from "react"
import { toast } from "sonner"
import { TriangleAlert } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { useCancelOrder, type AdminOrderDetail } from "@/lib/api/admin/orders"
import { getApiErrorMessage } from "@/lib/api/error"

export interface CancelOrderDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  order: Pick<AdminOrderDetail, "id" | "numeroPedido">
}

export function CancelOrderDialog({ open, onOpenChange, order }: CancelOrderDialogProps) {
  const [motivo, setMotivo] = useState("")
  const cancelOrder = useCancelOrder()

  async function handleConfirm() {
    const trimmed = motivo.trim()
    if (!trimmed) return

    try {
      await cancelOrder.mutateAsync({ id: order.id, motivo: trimmed })
      toast.success(`Pedido ${order.numeroPedido} cancelado`)
      setMotivo("")
      onOpenChange(false)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo cancelar el pedido"))
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <TriangleAlert className="size-5 text-destructive" />
            Cancelar pedido {order.numeroPedido}
          </DialogTitle>
          <DialogDescription>
            Indica el motivo. Este campo es obligatorio y quedará registrado en el historial.
          </DialogDescription>
        </DialogHeader>
        <div className="space-y-2">
          <Label htmlFor="cancel-motivo">Motivo de cancelación</Label>
          <Textarea
            id="cancel-motivo"
            value={motivo}
            onChange={(event) => setMotivo(event.target.value)}
            placeholder="Ej. El cliente pidió cancelar…"
            aria-invalid={motivo.length > 0 && motivo.trim().length === 0}
            autoFocus
          />
        </div>
        <DialogFooter>
          <Button variant="outline" disabled={cancelOrder.isPending} onClick={() => onOpenChange(false)}>
            No cancelar
          </Button>
          <Button
            variant="destructive"
            disabled={cancelOrder.isPending || motivo.trim().length === 0}
            onClick={() => void handleConfirm()}
          >
            {cancelOrder.isPending ? "Cancelando…" : "Cancelar pedido"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}