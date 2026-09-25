import { cn } from "cn"
import { Loader2, Pencil, Power, Trash2 } from "lucide-react"
import { Skeleton } from "@/components/ui/skeleton"
import { resolveCategoryIcon } from "@/components/features/categories/category-icon"
import type { CategoryResponse } from "@/lib/api/admin/categories"

export interface CategoryGridProps {
  categories: CategoryResponse[]
  onEdit: (category: CategoryResponse) => void
  onToggle: (category: CategoryResponse) => void
  onDelete: (category: CategoryResponse) => void
  pendingId: string | null
}

export function CategoryGrid({
  categories,
  onEdit,
  onToggle,
  onDelete,
  pendingId,
}: CategoryGridProps) {
  return (
    <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
      {categories.map((category) => {
        const { emoji, icon: Icon } = resolveCategoryIcon(category.icon, category.nombre)
        const isPending = pendingId === category.id
        return (
          <div
            key={category.id}
            className="group relative flex flex-col justify-between rounded-2xl border border-zinc-200 bg-white p-5 transition-all hover:border-zinc-300 hover:shadow-md"
          >
            <div className="mb-3 flex items-start justify-between">
              <div className="flex size-14 items-center justify-center rounded-2xl bg-zinc-100 text-zinc-900 transition-colors group-hover:bg-zinc-900 group-hover:text-white">
                {emoji ? (
                  <span className="text-2xl leading-none">{emoji}</span>
                ) : Icon ? (
                  <Icon className="size-7" strokeWidth={1.75} />
                ) : null}
              </div>
              <div className="flex flex-col items-end gap-1.5">
                <span
                  className={cn(
                    "inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-xs font-medium",
                    category.activo ? "bg-green-100 text-green-800" : "bg-zinc-100 text-zinc-500",
                  )}
                >
                  <span className="size-1.5 rounded-full bg-current opacity-70" aria-hidden="true" />
                  {category.activo ? "Activo" : "Inactivo"}
                </span>
                <span className="rounded-full border border-zinc-200 bg-white px-2 py-0.5 text-xs font-medium text-zinc-500">
                  #{category.orden}
                </span>
              </div>
            </div>

            <div className="min-h-[3.25rem]">
              <h3 className="mb-1 text-base font-bold text-zinc-900">{category.nombre}</h3>
              <p className="line-clamp-2 text-xs leading-relaxed text-zinc-500">
                {category.descripcion || "Sin descripción"}
              </p>
            </div>

            <div className="mt-auto flex items-center justify-between border-t border-zinc-100 pt-3 text-xs text-zinc-500">
              <span aria-hidden="true" />
              <div className="flex items-center gap-0.5">
                <button
                  type="button"
                  aria-label="Editar"
                  className="rounded-md p-1 text-zinc-500 transition-colors hover:bg-zinc-100 hover:text-zinc-900"
                  onClick={() => onEdit(category)}
                >
                  <Pencil className="size-4" />
                </button>
                <button
                  type="button"
                  aria-label={category.activo ? "Desactivar" : "Activar"}
                  disabled={isPending}
                  className="rounded-md p-1 text-zinc-500 transition-colors hover:bg-zinc-100 hover:text-zinc-900 disabled:pointer-events-none disabled:opacity-50"
                  onClick={() => onToggle(category)}
                >
                  {isPending ? (
                    <Loader2 className="size-4 animate-spin" />
                  ) : (
                    <Power className="size-4" />
                  )}
                </button>
                <button
                  type="button"
                  aria-label="Eliminar"
                  disabled={isPending}
                  className="rounded-md p-1 text-zinc-500 transition-colors hover:bg-red-50 hover:text-red-600 disabled:pointer-events-none disabled:opacity-50"
                  onClick={() => onDelete(category)}
                >
                  <Trash2 className="size-4" />
                </button>
              </div>
            </div>
          </div>
        )
      })}
    </div>
  )
}

export function CategoryGridSkeleton() {
  return (
    <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4">
      {Array.from({ length: 8 }).map((_, index) => (
        <div
          key={index}
          className="rounded-2xl border border-zinc-200 bg-white p-5 transition-all"
        >
          <Skeleton className="mb-3 size-14 rounded-2xl" />
          <Skeleton className="mb-2 h-5 w-2/3" />
          <Skeleton className="h-3 w-full" />
          <Skeleton className="mt-1 h-3 w-4/5" />
          <div className="mt-4 border-t border-zinc-100 pt-3">
            <Skeleton className="ml-auto size-6 rounded-md" />
          </div>
        </div>
      ))}
    </div>
  )
}