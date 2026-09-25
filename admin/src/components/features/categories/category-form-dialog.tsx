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
  useCreateCategory,
  useUpdateCategory,
  type CategoryResponse,
} from "@/lib/api/admin/categories"
import { getApiErrorMessage } from "@/lib/api/error"

const categoryFormSchema = z.object({
  nombre: z
    .string()
    .trim()
    .min(1, "El nombre es obligatorio")
    .max(80, "Máximo 80 caracteres"),
  descripcion: z.string().trim().max(500, "Máximo 500 caracteres"),
  orden: z
    .number({ error: "El orden es obligatorio" })
    .int("Usa un número entero")
    .min(0, "El orden no puede ser negativo"),
  activo: z.boolean(),
})

type CategoryFormValues = z.infer<typeof categoryFormSchema>

const EMPTY_VALUES: CategoryFormValues = {
  nombre: "",
  descripcion: "",
  orden: 0,
  activo: true,
}

export interface CategoryDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  category: CategoryResponse | null
}

export function CategoryFormDialog({ open, onOpenChange, category }: CategoryDialogProps) {
  const isEditing = category !== null
  const createCategory = useCreateCategory()
  const updateCategory = useUpdateCategory()
  const isPending = createCategory.isPending || updateCategory.isPending

  const form = useForm<CategoryFormValues>({
    resolver: zodResolver(categoryFormSchema),
    defaultValues: EMPTY_VALUES,
  })

  useEffect(() => {
    if (!open) return
    form.reset({
      nombre: category?.nombre ?? EMPTY_VALUES.nombre,
      descripcion: category?.descripcion ?? EMPTY_VALUES.descripcion,
      orden: category?.orden ?? EMPTY_VALUES.orden,
      activo: category?.activo ?? EMPTY_VALUES.activo,
    })
  }, [open, category, form])

  async function onSubmit(values: CategoryFormValues) {
    const base = {
      nombre: values.nombre,
      descripcion: values.descripcion || null,
      orden: values.orden,
    }

    try {
      if (isEditing) {
        await updateCategory.mutateAsync({
          id: category.id,
          data: { ...base, activo: values.activo },
        })
        toast.success("Categoría actualizada")
      } else {
        await createCategory.mutateAsync({ data: base })
        toast.success("Categoría creada")
      }
      onOpenChange(false)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo guardar la categoría"))
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{isEditing ? "Editar categoría" : "Nueva categoría"}</DialogTitle>
          <DialogDescription>
            {isEditing
              ? "Modifica los datos de la categoría."
              : "Crea una categoría para organizar el catálogo."}
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={(event) => void form.handleSubmit(onSubmit)(event)} className="space-y-4">
            <FormField
              control={form.control}
              name="nombre"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Nombre</FormLabel>
                  <FormControl>
                    <Input placeholder="Ej. Hamburguesas" {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name="descripcion"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Descripción</FormLabel>
                  <FormControl>
                    <Textarea
                      placeholder="Descripción opcional"
                      {...field}
                      value={field.value ?? ""}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <div className="grid grid-cols-2 gap-4">
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
              <FormField
                control={form.control}
                name="activo"
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
                          <SelectItem value="true">Activo</SelectItem>
                          <SelectItem value="false">Inactivo</SelectItem>
                        </SelectContent>
                      </Select>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            </div>

            <DialogFooter>
              <Button type="button" variant="outline" disabled={isPending} onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending ? "Guardando…" : isEditing ? "Guardar cambios" : "Crear categoría"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}