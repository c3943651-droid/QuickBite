import { Package, RefreshCw, Utensils } from "lucide-react"
import { Button } from "@/components/ui/button"
import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { StatusChip } from "@/components/common/status-chip"
import { Skeleton } from "@/components/ui/skeleton"
import { cn } from "cn"
import { useAdminProductDetail, type ProductListItem } from "@/lib/api/admin/products"
import { formatCurrency } from "@/lib/format"

export interface ProductDetailDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  product: ProductListItem | null
  onEdit: (product: ProductListItem) => void
}

export function ProductDetailDialog({
  open,
  onOpenChange,
  product,
  onEdit,
}: ProductDetailDialogProps) {
  const { data: detail, isLoading, isError, refetch } = useAdminProductDetail(
    product?.id ?? null,
    { enabled: open },
  )

  const resolved = detail ?? product

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[calc(100vh-4rem)] overflow-y-auto sm:max-w-xl">
        <DialogHeader>
          {resolved?.categoria ? (
            <DialogDescription>
              {resolved.categoria.nombre}
            </DialogDescription>
          ) : (
            <DialogDescription>Sin categoría</DialogDescription>
          )}
          <DialogTitle>{resolved?.nombre ?? "Detalle del producto"}</DialogTitle>
        </DialogHeader>

        {resolved ? (
          <div className="space-y-4">
            <div className="flex items-center justify-between gap-3">
              <StatusChip status={resolved.disponible ? "Disponible" : "No disponible"} />
              <div className="text-right">
                <p className="text-xs text-zinc-500">Precio actual</p>
                <p className="text-xl font-bold text-zinc-900 tabular-nums">
                  {formatCurrency(resolved.precio)}
                </p>
              </div>
            </div>

            <div className="overflow-hidden rounded-lg bg-zinc-100">
              {resolved.imagenUrl ? (
                <img
                  src={resolved.imagenUrl}
                  alt={`Foto de ${resolved.nombre}`}
                  className="h-44 w-full object-cover"
                />
              ) : (
                <div className="flex h-44 items-center justify-center">
                  <Utensils className="size-10 text-zinc-300" />
                </div>
              )}
            </div>

            <section className="space-y-1">
              <h4 className="flex items-center gap-1.5 text-xs font-semibold tracking-wider text-zinc-400 uppercase">
                Descripción
              </h4>
              <p className="text-sm whitespace-pre-line text-zinc-700">
                {resolved.descripcion?.trim() ? resolved.descripcion : "Sin descripción."}
              </p>
            </section>

            <section className="rounded-lg border border-zinc-100 p-4">
              <h4 className="flex items-center gap-1.5 text-xs font-semibold tracking-wider text-zinc-400 uppercase">
                <Package className="size-3.5" />
                Inventario
              </h4>
              <dl className="mt-2 grid grid-cols-2 gap-3">
                <div>
                  <dt className="text-xs text-zinc-500">Stock actual</dt>
                  <dd className="text-base font-semibold text-zinc-900 tabular-nums">
                    {detail?.stock ?? product?.stock ?? "—"}
                  </dd>
                </div>
                <div>
                  <dt className="text-xs text-zinc-500">Stock mínimo</dt>
                  <dd className="text-base font-semibold text-zinc-900 tabular-nums">
                    {product?.stockMinimo ?? "—"}
                  </dd>
                </div>
              </dl>
            </section>

            <section className="space-y-2">
              <h4 className="text-xs font-semibold tracking-wider text-zinc-400 uppercase">
                Opciones personalizables
              </h4>
              {isLoading ? (
                <div className="space-y-2">
                  {Array.from({ length: 3 }).map((_, index) => (
                    <Skeleton key={index} className="h-9" />
                  ))}
                </div>
              ) : isError ? (
                <div className="flex items-center justify-between gap-2 rounded-lg border border-dashed border-zinc-200 px-3 py-4">
                  <p className="text-sm text-zinc-500">No se pudieron cargar las opciones.</p>
                  <Button variant="outline" size="sm" onClick={() => void refetch()}>
                    <RefreshCw className="size-3.5" />
                    Reintentar
                  </Button>
                </div>
              ) : (detail?.opciones ?? []).length === 0 ? (
                <p className="text-sm text-zinc-500">Sin opciones configuradas.</p>
              ) : (
                <ul className="divide-y divide-zinc-100 overflow-hidden rounded-lg border border-zinc-100">
                  {(detail?.opciones ?? []).map((opcion) => (
                    <li
                      key={opcion.id}
                      className={cn(
                        "flex items-center justify-between gap-3 bg-white px-3 py-2.5",
                        !opcion.activo && "opacity-60",
                      )}
                    >
                      <span className="min-w-0 text-sm font-medium text-zinc-800">
                        <span className="block truncate">{opcion.nombre}</span>
                        {!opcion.activo ? (
                          <span className="block text-xs font-normal text-zinc-500">Inactiva</span>
                        ) : null}
                      </span>
                      <span
                        className={cn(
                          "shrink-0 text-sm tabular-nums",
                          opcion.precioAdicional > 0
                            ? "font-semibold text-zinc-900"
                            : "text-muted-foreground",
                        )}
                      >
                        {opcion.precioAdicional > 0
                          ? `+ ${formatCurrency(opcion.precioAdicional)}`
                          : "Sin costo adicional"}
                      </span>
                    </li>
                  ))}
                </ul>
              )}
            </section>
          </div>
        ) : null}

        <DialogFooter>
          <DialogClose asChild>
            <Button variant="outline">Cerrar</Button>
          </DialogClose>
          {product ? (
            <Button onClick={() => onEdit(product)}>
              Editar producto
            </Button>
          ) : null}
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}