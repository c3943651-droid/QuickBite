import { useEffect } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { toast } from "sonner"
import { z } from "zod"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Textarea } from "@/components/ui/textarea"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { useAdjustStock } from "@/lib/api/admin/inventory"
import type { ProductListItem } from "@/lib/api/admin/products"
import { getApiErrorMessage } from "@/lib/api/error"
import { formatCurrency } from "@/lib/format"

const stockAdjustSchema = z.object({
  cantidad: z
    .number({ error: "La cantidad es obligatoria" })
    .int("Usa un número entero")
    .min(0, "No puede ser negativa"),
  motivo: z.string().trim().min(2, "El motivo es obligatorio").max(200, "Máximo 200 caracteres"),
})

type StockAdjustValues = z.infer<typeof stockAdjustSchema>

const EMPTY_VALUES: StockAdjustValues = {
  cantidad: 0,
  motivo: "",
}

export interface StockAdjustDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  product: ProductListItem | null
}

export function StockAdjustDialog({ open, onOpenChange, product }: StockAdjustDialogProps) {
  const adjustStock = useAdjustStock()

  const form = useForm<StockAdjustValues>({
    resolver: zodResolver(stockAdjustSchema),
    defaultValues: EMPTY_VALUES,
  })

  useEffect(() => {
    if (!open) return
    form.reset({
      cantidad: product?.stock ?? 0,
      motivo: EMPTY_VALUES.motivo,
    })
  }, [open, product, form])

  async function onSubmit(values: StockAdjustValues) {
    if (!product) return
    try {
      await adjustStock.mutateAsync({
        id: product.id,
        stock: values.cantidad,
        motivo: values.motivo,
      })
      toast.success(`Stock de "${product.nombre}" actualizado a ${values.cantidad}`)
      onOpenChange(false)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo ajustar el stock"))
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>Ajustar stock</DialogTitle>
          <DialogDescription>
            Establece el nuevo nivel de inventario para el producto.
          </DialogDescription>
        </DialogHeader>

        {product ? (
          <div className="rounded-lg border p-3">
            <div className="flex items-center gap-3">
              {product.imagenUrl ? (
                <img
                  src={product.imagenUrl}
                  alt=""
                  className="size-10 rounded-md border border-border object-cover"
                />
              ) : null}
              <div className="min-w-0">
                <p className="truncate font-medium">{product.nombre}</p>
                <p className="text-muted-foreground text-xs">
                  Precio: {formatCurrency(product.precio)}
                  {product.stockMinimo !== null
                    ? ` · Stock mínimo: ${product.stockMinimo}`
                    : ""}
                </p>
              </div>
            </div>
          </div>
        ) : null}

        <Form {...form}>
          <form onSubmit={(event) => void form.handleSubmit(onSubmit)(event)} className="space-y-4">
            <FormField
              control={form.control}
              name="cantidad"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Cantidad (stock total)</FormLabel>
                  <FormControl>
                    <Input
                      type="number"
                      min="0"
                      placeholder="0"
                      {...field}
                      onChange={(event) => field.onChange(event.target.valueAsNumber || undefined)}
                    />
                  </FormControl>
                  <FormDescription>
                    Este valor reemplaza al stock actual ({product?.stock ?? "—"} unidades).
                  </FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="motivo"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Motivo</FormLabel>
                  <FormControl>
                    <Textarea
                      placeholder="Ej. Recepción de mercancía, merma, inventario físico…"
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <DialogFooter>
              <Button type="button" variant="outline" disabled={adjustStock.isPending} onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={adjustStock.isPending}>
                {adjustStock.isPending ? "Guardando…" : "Guardar stock"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}