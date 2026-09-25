import { useState } from "react"
import { cn } from "cn"
import { Eraser } from "lucide-react"
import {
  CATEGORY_EMOJIS,
  CATEGORY_LUCIDE_ICONS,
  isEmoji,
} from "@/components/features/categories/category-icon"

export interface CategoryIconPickerProps {
  value: string | null
  onChange: (value: string | null) => void
}

type IconTab = "emoji" | "lucide"

export function CategoryIconPicker({ value, onChange }: CategoryIconPickerProps) {
  const [tab, setTab] = useState<IconTab>(() =>
    value !== null && isEmoji(value) ? "emoji" : "lucide",
  )
  const hasSelection = value !== null

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-0.5 rounded-lg bg-zinc-100 p-0.5">
          <button
            type="button"
            aria-pressed={tab === "emoji"}
            className={cn(
              "rounded-md px-2.5 py-1 text-xs font-medium transition-colors",
              tab === "emoji"
                ? "bg-white text-zinc-900 shadow-sm"
                : "text-zinc-500 hover:text-zinc-800",
            )}
            onClick={() => setTab("emoji")}
          >
            Emojis
          </button>
          <button
            type="button"
            aria-pressed={tab === "lucide"}
            className={cn(
              "rounded-md px-2.5 py-1 text-xs font-medium transition-colors",
              tab === "lucide"
                ? "bg-white text-zinc-900 shadow-sm"
                : "text-zinc-500 hover:text-zinc-800",
            )}
            onClick={() => setTab("lucide")}
          >
            Íconos
          </button>
        </div>
        <button
          type="button"
          disabled={!hasSelection}
          className="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-medium text-zinc-500 transition-colors hover:bg-zinc-100 hover:text-zinc-800 disabled:pointer-events-none disabled:opacity-50"
          onClick={() => onChange(null)}
        >
          <Eraser className="size-3.5" />
          Sin ícono
        </button>
      </div>

      {tab === "emoji" ? (
        <div className="grid grid-cols-5 gap-2">
          {CATEGORY_EMOJIS.map((option) => {
            const selected = value === option.value
            return (
              <button
                key={option.value}
                type="button"
                aria-label={option.label}
                title={option.label}
                aria-pressed={selected}
                className={cn(
                  "aspect-square rounded-lg border text-xl transition-colors",
                  selected
                    ? "border-zinc-900 bg-zinc-900 text-white"
                    : "border-zinc-200 bg-white text-zinc-800 hover:border-zinc-300 hover:bg-zinc-50",
                )}
                onClick={() => onChange(option.value)}
              >
                {option.value}
              </button>
            )
          })}
        </div>
      ) : (
        <div className="grid grid-cols-5 gap-2">
          {CATEGORY_LUCIDE_ICONS.map((option) => {
            const selected = value === option.name
            const Icon = option.icon
            return (
              <button
                key={option.name}
                type="button"
                aria-label={option.label}
                title={option.label}
                aria-pressed={selected}
                className={cn(
                  "flex aspect-square items-center justify-center rounded-lg border transition-colors",
                  selected
                    ? "border-zinc-900 bg-zinc-900 text-white"
                    : "border-zinc-200 bg-white text-zinc-700 hover:border-zinc-300 hover:bg-zinc-50",
                )}
                onClick={() => onChange(option.name)}
              >
                <Icon className="size-5" strokeWidth={1.75} />
              </button>
            )
          })}
        </div>
      )}

      <p className="text-xs text-zinc-500">
        {hasSelection
          ? value !== null && isEmoji(value)
            ? `Emoji seleccionado: ${value}`
            : "Ícono Lucide seleccionado"
          : "Sin seleccionar: se deducirá automáticamente del nombre."}
      </p>
    </div>
  )
}