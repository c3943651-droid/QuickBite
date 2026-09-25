import { History } from "lucide-react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { ErrorState } from "@/components/common/error-state"
import { Skeleton } from "@/components/ui/skeleton"
import {
  useAdminProductPriceHistory,
  type ProductListItem,
} from "@/lib/api/admin/products"
import { formatCurrency, formatDateTime } from "@/lib/format"

export interface ProductPriceHistoryDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  product: ProductListItem | null
}

export function ProductPriceHistoryDialog({
  open,
  onOpenChange,
  product,
}: ProductPriceHistoryDialogProps) {
  const { data, isLoading, isError, refetch } = useAdminProductPriceHistory(product?.id ?? null)

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Historial de precios</DialogTitle>
          {product ? (
            <DialogDescription>
              Cambios de precio de {product.nombre}.
            </DialogDescription>
          ) : null}
        </DialogHeader>

        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 4 }).map((_, index) => (
              <Skeleton key={index} className="h-10" />
            ))}
          </div>
        ) : isError ? (
          <ErrorState
            title="No se pudo cargar el historial"
            description="Revisa tu conexión o intenta nuevamente."
            onRetry={() => void refetch()}
          />
        ) : (data ?? []).length === 0 ? (
          <div className="rounded-xl border border-dashed border-zinc-200 bg-zinc-50/50 p-8 text-center">
            <History className="mx-auto mb-2 size-8 text-zinc-400" />
            <p className="text-sm font-medium text-zinc-600">Sin cambios de precio</p>
            <p className="mt-1 text-sm text-zinc-500">
              Este producto no ha tenido cambios de precio.
            </p>
          </div>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Fecha</TableHead>
                <TableHead className="text-right">Precio anterior</TableHead>
                <TableHead className="text-right">Precio nuevo</TableHead>
                <TableHead>Usuario</TableHead>
                <TableHead>Motivo</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {data?.map((entry) => (
                <TableRow key={entry.id}>
                  <TableCell>{formatDateTime(entry.creadoEn)}</TableCell>
                  <TableCell className="text-right tabular-nums">
                    {formatCurrency(entry.precioAnterior)}
                  </TableCell>
                  <TableCell className="text-right tabular-nums font-medium">
                    {formatCurrency(entry.precioNuevo)}
                  </TableCell>
                  <TableCell>{entry.usuario ?? "—"}</TableCell>
                  <TableCell>{entry.motivo ?? "—"}</TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </DialogContent>
    </Dialog>
  )
}