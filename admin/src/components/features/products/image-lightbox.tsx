import { XIcon } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Dialog, DialogClose, DialogContent, DialogTitle } from "@/components/ui/dialog"
import type { ProductListItem } from "@/lib/api/admin/products"

export interface ImageLightboxProps {
  product: ProductListItem
  onClose: () => void
}

export function ImageLightbox({ product, onClose }: ImageLightboxProps) {
  if (!product.imagenUrl) return null

  return (
    <Dialog open onOpenChange={(open) => { if (!open) onClose() }}>
      <DialogContent
        showCloseButton={false}
        className="max-w-[calc(100%-1.5rem)] gap-0 overflow-hidden p-0 sm:max-w-[min(64rem,calc(100%-2rem))]"
      >
        <div className="flex items-center justify-between gap-4 border-b border-zinc-100 px-5 py-3.5">
          <div className="min-w-0">
            <p className="truncate text-xs font-semibold tracking-wider text-zinc-400 uppercase">
              {product.categoria ? product.categoria.nombre : "Sin categoría"}
            </p>
            <DialogTitle className="text-lg">{product.nombre}</DialogTitle>
          </div>
          <DialogClose asChild>
            <Button
              variant="ghost"
              size="icon-sm"
              aria-label="Cerrar vista previa"
              className="shrink-0 text-zinc-500"
            >
              <XIcon className="size-5" />
            </Button>
          </DialogClose>
        </div>
        <div className="flex max-h-[75vh] items-center justify-center bg-zinc-50 p-4">
          <img
            src={product.imagenUrl}
            alt={`Imagen original de ${product.nombre}`}
            className="max-h-[70vh] w-auto max-w-full rounded-lg object-contain"
          />
        </div>
      </DialogContent>
    </Dialog>
  )
}