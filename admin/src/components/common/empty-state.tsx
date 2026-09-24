import type { ReactNode } from "react"
import { cn } from "cn"
import { Inbox, type LucideIcon } from "lucide-react"

export interface EmptyStateProps {
  title?: string
  description?: string
  icon?: LucideIcon
  action?: ReactNode
  className?: string
}

export function EmptyState({
  title = "Sin datos",
  description = "No hay registros para mostrar.",
  icon: Icon = Inbox,
  action,
  className,
}: EmptyStateProps) {
  return (
    <div
      className={cn(
        "flex flex-col items-center justify-center gap-2 rounded-lg border border-dashed px-6 py-12 text-center",
        className,
      )}
    >
      <Icon className="size-10 text-muted-foreground/50" />
      <p className="font-medium">{title}</p>
      {description ? <p className="max-w-sm text-sm text-muted-foreground">{description}</p> : null}
      {action ? <div className="mt-2">{action}</div> : null}
    </div>
  )
}