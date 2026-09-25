import { cn } from "cn"
import { History, Loader2, MoreHorizontal, Pencil, Power, Trash2, Utensils } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardFooter } from "@/components/ui/card"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { StatusChip } from "@/components/common/status-chip"
import { Skeleton } from "@/components/ui/skeleton"
import { formatCurrency } from "@/lib/format"
import type { ProductListItem } from "@/lib/api/admin/products"

export interface ProductActionsMenuProps {
  product: ProductListItem
  onEdit: (product: ProductListItem) => void
  onToggle: (product: ProductListItem) => void
  onHistory: (product: ProductListItem) => void
  onDelete: (product: ProductListItem) => void
  disabled?: boolean
  triggerClassName?: string
}

export function ProductActionsMenu({
  product,
  onEdit,
  onToggle,
  onHistory,
  onDelete,
  disabled,
  triggerClassName,
}: ProductActionsMenuProps) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon-sm"
          aria-label="Acciones"
          disabled={disabled}
          className={cn("text-zinc-500", triggerClassName)}
        >
          <MoreHorizontal className="size-4" />
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        <DropdownMenuItem onClick={() => onEdit(product)}>
          <Pencil className="size-4 text-zinc-500" />
          Editar
        </DropdownMenuItem>
        <DropdownMenuItem disabled={disabled} onClick={() => onToggle(product)}>
          <Power
            className={cn("size-4 text-zinc-500", !product.disponible && "text-muted-foreground")}
          />
          {product.disponible ? "Desactivar" : "Activar"}
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => onHistory(product)}>
          <History className="size-4 text-zinc-500" />
          Historial de precios
        </DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem variant="destructive" onClick={() => onDelete(product)}>
          <Trash2 className="size-4" />
          Eliminar
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}

function productStatusBadge(product: ProductListItem) {
  if (!product.disponible) return { label: "Inactivo", className: undefined }
  if (product.stock !== null && product.stock <= 0) {
    return { label: "Agotado", className: "bg-red-100 text-red-800" }
  }
  return { label: "Disponible", className: undefined }
}

export interface ProductGridProps {
  products: ProductListItem[]
  onEdit: (product: ProductListItem) => void
  onToggle: (product: ProductListItem) => void
  onHistory: (product: ProductListItem) => void
  onDelete: (product: ProductListItem) => void
  pendingId: string | null
}

export function ProductGrid({
  products,
  onEdit,
  onToggle,
  onHistory,
  onDelete,
  pendingId,
}: ProductGridProps) {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {products.map((product) => {
        const status = productStatusBadge(product)
        const isPending = pendingId === product.id
        return (
          <Card key={product.id} size="sm" className="relative flex flex-col gap-0 pt-0">
            <div className="relative aspect-video w-full">
              {product.imagenUrl ? (
                <img
                  src={product.imagenUrl}
                  alt={`Foto de ${product.nombre}`}
                  className="size-full object-cover"
                />
              ) : (
                <div className="flex size-full items-center justify-center bg-zinc-100">
                  <Utensils className="size-8 text-zinc-300" />
                </div>
              )}
              <div className="absolute top-2 left-2">
                <StatusChip status={status.label} className={status.className} />
              </div>
              <div className="absolute top-2 right-2">
                <ProductActionsMenu
                  product={product}
                  onEdit={onEdit}
                  onToggle={onToggle}
                  onHistory={onHistory}
                  onDelete={onDelete}
                  disabled={isPending}
                  triggerClassName="bg-black/40 text-white backdrop-blur-md hover:bg-black/60 hover:text-white"
                />
              </div>
            </div>
            <CardContent className="pt-4">
              <p className="text-xs font-semibold uppercase tracking-wider text-zinc-400">
                {product.categoria ? product.categoria.nombre : "Sin categoría"}
              </p>
              <h3 className="mt-1 truncate text-base font-bold text-zinc-900">{product.nombre}</h3>
              <p className="mt-1 text-lg font-bold text-zinc-900">
                {formatCurrency(product.precio)}
              </p>
            </CardContent>
            <CardFooter className="mt-auto justify-between">
              <span className="text-xs font-medium text-zinc-500">
                {product.stock === null ? "Stock: —" : `Stock: ${product.stock}`}
                {product.stockMinimo !== null ? ` / mín. ${product.stockMinimo}` : ""}
              </span>
              <Button
                variant="ghost"
                size="icon-sm"
                aria-label={product.disponible ? "Desactivar" : "Activar"}
                className="text-zinc-500"
                disabled={isPending}
                onClick={() => onToggle(product)}
              >
                {isPending ? (
                  <Loader2 className="size-4 animate-spin" />
                ) : (
                  <Power className="size-4" />
                )}
              </Button>
            </CardFooter>
          </Card>
        )
      })}
    </div>
  )
}

export function ProductGridSkeleton() {
  return (
    <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {Array.from({ length: 8 }).map((_, index) => (
        <Card key={index} size="sm" className="gap-0 pt-0">
          <Skeleton className="aspect-video w-full rounded-none" />
          <CardContent className="space-y-2 pt-4">
            <Skeleton className="h-3 w-20" />
            <Skeleton className="h-4 w-32" />
            <Skeleton className="h-5 w-16" />
          </CardContent>
        </Card>
      ))}
    </div>
  )
}