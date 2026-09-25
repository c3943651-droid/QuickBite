import type { ReactNode } from "react"
import { cn } from "cn"
import { TriangleAlert, type LucideIcon } from "lucide-react"
import { Button } from "@/components/ui/button"

export interface ErrorStateProps {
  title?: string
  description?: string
  icon?: LucideIcon
  onRetry?: () => void
  action?: ReactNode
  className?: string
}

export function ErrorState({
  title = "Algo salió mal",
  description = "No se pudieron cargar los datos. Inténtalo de nuevo.",
  icon: Icon = TriangleAlert,
  onRetry,
  action,
  className,
}: ErrorStateProps) {
  return (
    <div
      className={cn(
        "flex flex-col items-center justify-center gap-2 rounded-lg border border-dashed px-6 py-12 text-center",
        className,
      )}
    >
      <Icon className="size-10 text-destructive/70" />
      <p className="font-medium">{title}</p>
      {description ? <p className="max-w-sm text-sm text-muted-foreground">{description}</p> : null}
      {onRetry ? (
        <Button variant="outline" size="sm" className="mt-2" onClick={onRetry}>
          Reintentar
        </Button>
      ) : null}
      {action ? <div className="mt-2">{action}</div> : null}
    </div>
  )
}