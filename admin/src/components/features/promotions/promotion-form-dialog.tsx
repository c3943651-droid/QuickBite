import { useEffect, useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { toast } from "sonner"
import { z } from "zod"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
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
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  useCreatePromotion,
  useUpdatePromotion,
  type PromotionResponse,
} from "@/lib/api/admin/promotions"
import { getApiErrorMessage } from "@/lib/api/error"

const promotionFormSchema = z.object({
  titulo: z
    .string()
    .trim()
    .min(1, "El título es obligatorio")
    .max(100, "Máximo 100 caracteres"),
  subtitulo: z.string().trim().max(200, "Máximo 200 caracteres"),
  colorHex: z
    .string()
    .regex(/^#[0-9A-Fa-f]{6}$/, "Debe ser un color hexadecimal válido (#RRGGBB)"),
  orden: z
    .number({ error: "El orden es obligatorio" })
    .int("Usa un número entero")
    .min(0, "El orden no puede ser negativo"),
  activa: z.boolean(),
})

type PromotionFormValues = z.infer<typeof promotionFormSchema>

const EMPTY_VALUES: PromotionFormValues = {
  titulo: "",
  subtitulo: "",
  colorHex: "#0D9488",
  orden: 0,
  activa: true,
}

export interface PromotionDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  promotion: PromotionResponse | null
}

export function PromotionFormDialog({ open, onOpenChange, promotion }: PromotionDialogProps) {
  const isEditing = promotion !== null
  const createPromotion = useCreatePromotion()
  const updatePromotion = useUpdatePromotion()
  const isPending = createPromotion.isPending || updatePromotion.isPending

  const form = useForm<PromotionFormValues>({
    resolver: zodResolver(promotionFormSchema),
    defaultValues: EMPTY_VALUES,
  })

  useEffect(() => {
    if (!open) return
    form.reset({
      titulo: promotion?.titulo ?? EMPTY_VALUES.titulo,
      subtitulo: promotion?.subtitulo ?? EMPTY_VALUES.subtitulo,
      colorHex: promotion?.colorHex ?? EMPTY_VALUES.colorHex,
      orden: 0,
      activa: true,
    })
  }, [open, promotion, form])

  async function onSubmit(values: PromotionFormValues) {
    try {
      if (isEditing) {
        await updatePromotion.mutateAsync({
          id: promotion.id,
          data: { titulo: values.titulo, subtitulo: values.subtitulo, colorHex: values.colorHex },
        })
        toast.success("Promoción actualizada")
      } else {
        await createPromotion.mutateAsync({
          data: {
            titulo: values.titulo,
            subtitulo: values.subtitulo,
            colorHex: values.colorHex,
            orden: values.orden,
          },
        })
        toast.success("Promoción creada")
      }
      onOpenChange(false)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo guardar la promoción"))
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{isEditing ? "Editar promoción" : "Nueva promoción"}</DialogTitle>
          <DialogDescription>
            {isEditing
              ? "Modifica los datos de la promoción."
              : "Crea una promoción para mostrar en el catálogo."}
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={(event) => void form.handleSubmit(onSubmit)(event)} className="space-y-4">
            <FormField
              control={form.control}
              name="titulo"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Título</FormLabel>
                  <FormControl>
                    <Input placeholder="Ej. 2x1 en Tacos" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="subtitulo"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Subtítulo</FormLabel>
                  <FormControl>
                    <Input placeholder="Ej. Solo hoy" {...field} value={field.value ?? ""} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="grid grid-cols-2 gap-4">
              <FormField
                control={form.control}
                name="colorHex"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Color</FormLabel>
                    <FormControl>
                      <div className="flex items-center gap-2">
                        <input
                          type="color"
                          value={field.value}
                          onChange={field.onChange}
                          className="h-9 w-9 cursor-pointer rounded border-0 bg-transparent p-0"
                        />
                        <Input
                          placeholder="#0D9488"
                          {...field}
                          className="flex-1"
                        />
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <FormField
                control={form.control}
                name="orden"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Orden</FormLabel>
                    <FormControl>
                      <Input
                        type="number"
                        placeholder="0"
                        {...field}
                        onChange={(event) => field.onChange(event.target.valueAsNumber || undefined)}
                      />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            {!isEditing && (
              <FormField
                control={form.control}
                name="activa"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Estado</FormLabel>
                    <FormControl>
                      <Select
                        value={String(field.value)}
                        onValueChange={(value) => field.onChange(value === "true")}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="true">Activa</SelectItem>
                          <SelectItem value="false">Inactiva</SelectItem>
                        </SelectContent>
                      </Select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            )}

            <DialogFooter>
              <Button
                type="button"
                variant="secondary"
                className="h-9 px-4 bg-zinc-100 text-zinc-700 hover:bg-zinc-200"
                disabled={isPending}
                onClick={() => onOpenChange(false)}
              >
                Cancelar
              </Button>
              <Button type="submit" className="h-9 px-4" disabled={isPending}>
                {isPending ? "Guardando…" : isEditing ? "Guardar cambios" : "Crear promoción"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}
