import { Loader2 } from "lucide-react"
import { cn } from "cn"
import { Button } from "@/components/ui/button"
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"

export interface ConfirmDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  description?: string
  confirmLabel?: string
  cancelLabel?: string
  destructive?: boolean
  tone?: "default" | "amber"
  loading?: boolean
  onConfirm: () => void
  className?: string
}

const toneClasses = {
  default: "bg-zinc-900 text-white hover:bg-zinc-800",
  amber: "bg-amber-600 text-white hover:bg-amber-700",
}

export function ConfirmDialog({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel = "Confirmar",
  cancelLabel = "Cancelar",
  destructive = false,
  tone = "default",
  loading = false,
  onConfirm,
  className,
}: ConfirmDialogProps) {
  return (
    <AlertDialog open={open} onOpenChange={(value) => !loading && onOpenChange(value)}>
      <AlertDialogContent className={className}>
        <AlertDialogHeader>
          <AlertDialogTitle>{title}</AlertDialogTitle>
          {description ? <AlertDialogDescription>{description}</AlertDialogDescription> : null}
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel asChild>
            <Button
              variant="secondary"
              className="bg-zinc-100 text-zinc-700 hover:bg-zinc-200"
              disabled={loading}
            >
              {cancelLabel}
            </Button>
          </AlertDialogCancel>
          <Button
            variant={destructive ? "destructive" : "default"}
            className={cn(!destructive && toneClasses[tone])}
            disabled={loading}
            onClick={() => onConfirm()}
          >
            {loading ? <Loader2 className="animate-spin" /> : null}
            {loading ? "Procesando…" : confirmLabel}
          </Button>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}