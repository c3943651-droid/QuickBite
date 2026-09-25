import { UtensilsCrossed } from "lucide-react"
import { cn } from "cn"

type BrandTone = "dark" | "light"

function Brand({
  compact = false,
  tone = "dark",
}: {
  compact?: boolean
  tone?: BrandTone
}) {
  const onDark = tone === "dark"
  return (
    <div
      className={compact ? "flex items-center justify-center gap-2.5" : "flex items-center gap-3"}
    >
      <span
        className={cn(
          "flex h-8 w-8 items-center justify-center rounded-lg shadow-sm",
          onDark ? "bg-zinc-800 ring-1 ring-white/10" : "bg-zinc-900",
        )}
      >
        <UtensilsCrossed className={cn("size-4", onDark ? "text-zinc-300" : "text-zinc-100")} />
      </span>
      <span
        className={cn(
          "text-lg font-bold tracking-tight",
          onDark ? "text-zinc-100" : "text-zinc-900",
        )}
      >
        QuickBite
      </span>
      <span
        className={cn(
          "rounded-full border px-2 py-0.5 text-[10px] font-bold tracking-widest uppercase",
          onDark
            ? "border-zinc-700/50 bg-zinc-800/80 text-zinc-300"
            : "border-zinc-200 bg-zinc-100 text-zinc-600",
        )}
      >
        Admin
      </span>
    </div>
  )
}

export { Brand }
export type { BrandTone }