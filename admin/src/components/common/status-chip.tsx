import { cn } from "cn"

const STATUS_STYLES: Record<string, string> = {
  Pendiente: "bg-amber-100 text-amber-800 dark:bg-amber-500/15 dark:text-amber-300",
  Confirmado: "bg-blue-100 text-blue-800 dark:bg-blue-500/15 dark:text-blue-300",
  Preparando: "bg-violet-100 text-violet-800 dark:bg-violet-500/15 dark:text-violet-300",
  Listo: "bg-sky-100 text-sky-800 dark:bg-sky-500/15 dark:text-sky-300",
  EnCamino: "bg-indigo-100 text-indigo-800 dark:bg-indigo-500/15 dark:text-indigo-300",
  Entregado: "bg-green-100 text-green-800 dark:bg-green-500/15 dark:text-green-300",
  Cancelado: "bg-red-100 text-red-800 dark:bg-red-500/15 dark:text-red-300",
  Disponible: "bg-green-100 text-green-800 dark:bg-green-500/15 dark:text-green-300",
  Ocupado: "bg-amber-100 text-amber-800 dark:bg-amber-500/15 dark:text-amber-300",
  Inactivo: "bg-muted text-muted-foreground",
}

const DEFAULT_STYLE = "bg-muted text-muted-foreground"

function normalize(status: string): string {
  const labels: Record<string, string> = {
    "en camino": "EnCamino",
    en_camino: "EnCamino",
    enCamino: "EnCamino",
    disponible: "Disponible",
    ocupado: "Ocupado",
    activo: "Disponible",
  }
  return labels[status] ?? status
}

export function StatusChip({
  status,
  className,
}: {
  status: string
  className?: string
}) {
  const normalized = normalize(status)
  const style = STATUS_STYLES[normalized] ?? DEFAULT_STYLE

  return (
    <span
      data-slot="status-chip"
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-xs font-medium whitespace-nowrap",
        style,
        className,
      )}
    >
      <span className="size-1.5 rounded-full bg-current opacity-70" aria-hidden="true" />
      {status}
    </span>
  )
}