import { useEffect, useRef, useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { toast } from "sonner"
import { Loader2, Plus, Trash2 } from "lucide-react"
import { z } from "zod"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
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
import { useAdminCategories } from "@/lib/api/admin/categories"
import {
  useAdminProductDetail,
  useAdminProductOptions,
  useCreateProduct,
  useCreateProductOption,
  useDeleteProductOption,
  useUpdateProduct,
  useUpdateProductOption,
  useUploadProductImage,
  type ProductOption,
} from "@/lib/api/admin/products"
import { getApiErrorMessage } from "@/lib/api/error"
import { formatCurrency } from "@/lib/format"

const productFormSchema = z.object({
  nombre: z
    .string()
    .trim()
    .min(1, "El nombre es obligatorio")
    .max(120, "Máximo 120 caracteres"),
  descripcion: z.string().trim().max(2000, "Máximo 2000 caracteres"),
  precio: z
    .number({ error: "El precio es obligatorio" })
    .positive("Debe ser mayor a 0"),
  categoriaId: z.string().optional(),
  disponible: z.boolean(),
  stockInicial: z
    .number({ error: "El stock es obligatorio" })
    .int("Usa un número entero")
    .min(0, "No puede ser negativo"),
  stockMinimo: z
    .number({ error: "El stock mínimo es obligatorio" })
    .int("Usa un número entero")
    .min(0, "No puede ser negativo"),
  imagenUrl: z.string().optional(),
})

type ProductFormValues = z.infer<typeof productFormSchema>

const EMPTY_VALUES: ProductFormValues = {
  nombre: "",
  descripcion: "",
  precio: 0,
  categoriaId: undefined,
  disponible: true,
  stockInicial: 0,
  stockMinimo: 0,
  imagenUrl: undefined,
}

export interface ProductFormDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  productId: string | null
  stockMinimo?: number | null
}

export function ProductFormDialog({
  open,
  onOpenChange,
  productId,
  stockMinimo,
}: ProductFormDialogProps) {
  const isEditing = productId !== null
  const fileInputRef = useRef<HTMLInputElement>(null)

  const createProduct = useCreateProduct()
  const updateProduct = useUpdateProduct()
  const uploadImage = useUploadProductImage()
  const { data: categories = [] } = useAdminCategories()

  const { data: detail, isLoading: detailLoading } = useAdminProductDetail(productId, {
    enabled: open,
  })
  const { data: options = [] } = useAdminProductOptions(productId, { enabled: open })

  const createOption = useCreateProductOption()
  const updateOption = useUpdateProductOption()
  const deleteOption = useDeleteProductOption()

  const isSaving = createProduct.isPending || updateProduct.isPending
  const [optionName, setOptionName] = useState("")
  const [optionPrice, setOptionPrice] = useState("")
  const [optionPendingId, setOptionPendingId] = useState<string | null>(null)
  const [uploading, setUploading] = useState(false)

  const form = useForm<ProductFormValues>({
    resolver: zodResolver(productFormSchema),
    defaultValues: EMPTY_VALUES,
  })

  const watchedImageUrl = form.watch("imagenUrl")

  useEffect(() => {
    if (!open) return
    if (isEditing && !detail) return
    form.reset(
      isEditing && detail
        ? {
            nombre: detail.nombre,
            descripcion: detail.descripcion ?? "",
            precio: detail.precio,
            categoriaId: detail.categoria?.id,
            disponible: detail.disponible,
            stockInicial: detail.stock ?? 0,
            stockMinimo: stockMinimo ?? EMPTY_VALUES.stockMinimo,
            imagenUrl: detail.imagenUrl ?? undefined,
          }
        : EMPTY_VALUES,
    )
  }, [open, isEditing, detail, form])

  function handleOpenChange(next: boolean) {
    if (!next) {
      setOptionName("")
      setOptionPrice("")
    }
    onOpenChange(next)
  }

  async function handleFileChange(file: File | undefined) {
    if (!file) return
    setUploading(true)
    try {
      const result = await uploadImage.mutateAsync({ file })
      form.setValue("imagenUrl", result.imageUrl, { shouldDirty: true })
      toast.success("Imagen subida")
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo subir la imagen"))
    } finally {
      setUploading(false)
    }
  }

  async function onSubmit(values: ProductFormValues) {
    const base = {
      nombre: values.nombre,
      descripcion: values.descripcion || null,
      precio: values.precio,
      categoriaId: values.categoriaId || undefined,
      imagenUrl: values.imagenUrl || undefined,
      disponible: values.disponible,
    }

    try {
      if (isEditing && productId) {
        await updateProduct.mutateAsync({ id: productId, data: base })
        toast.success("Producto actualizado")
      } else {
        await createProduct.mutateAsync({
          data: {
            ...base,
            stockInicial: values.stockInicial,
            stockMinimo: values.stockMinimo,
          },
        })
        toast.success("Producto creado")
      }
      handleOpenChange(false)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo guardar el producto"))
    }
  }

  async function handleAddOption() {
    if (!productId) return
    const name = optionName.trim()
    const price = Number(optionPrice)
    if (!name) {
      toast.error("Escribe un nombre para la opción")
      return
    }
    if (!Number.isFinite(price) || price < 0) {
      toast.error("El precio adicional debe ser mayor o igual a 0")
      return
    }
    try {
      await createOption.mutateAsync({
        id: productId,
        data: { nombre: name, precioAdicional: price },
      })
      setOptionName("")
      setOptionPrice("")
      toast.success("Opción agregada")
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo agregar la opción"))
    }
  }

  async function handleToggleOption(option: ProductOption) {
    if (!productId) return
    setOptionPendingId(option.id)
    try {
      await updateOption.mutateAsync({
        id: productId,
        optionId: option.id,
        data: { activo: !option.activo },
      })
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo actualizar la opción"))
    } finally {
      setOptionPendingId(null)
    }
  }

  async function handleDeleteOption(option: ProductOption) {
    if (!productId) return
    setOptionPendingId(option.id)
    try {
      await deleteOption.mutateAsync({ id: productId, optionId: option.id })
      toast.success(`Opción "${option.nombre}" eliminada`)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo eliminar la opción"))
    } finally {
      setOptionPendingId(null)
    }
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{isEditing ? "Editar producto" : "Nuevo producto"}</DialogTitle>
          <DialogDescription>
            {isEditing
              ? "Modifica los datos del producto y sus opciones."
              : "Agrega un producto al catálogo."}
          </DialogDescription>
        </DialogHeader>

        <div className="max-h-[70vh] overflow-y-auto pr-1">
          <Form {...form}>
            <form onSubmit={(event) => void form.handleSubmit(onSubmit)(event)} className="space-y-4">
              <div className="grid gap-4 sm:grid-cols-2">
                <FormField
                  control={form.control}
                  name="nombre"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Nombre</FormLabel>
                      <FormControl>
                        <Input placeholder="Ej. Clásica doble" {...field} />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="precio"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Precio</FormLabel>
                      <FormControl>
                        <Input
                          type="number"
                          step="0.01"
                          min="0"
                          placeholder="0.00"
                          {...field}
                          onChange={(event) => field.onChange(event.target.valueAsNumber || undefined)}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              <FormField
                control={form.control}
                name="descripcion"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Descripción</FormLabel>
                    <FormControl>
                      <Textarea placeholder="Descripción opcional" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />

              <div className="grid gap-4 sm:grid-cols-2">
                <FormField
                  control={form.control}
                  name="categoriaId"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Categoría</FormLabel>
                      <FormControl>
                        <Select
                          value={field.value ?? ""}
                          onValueChange={(value) => field.onChange(value || undefined)}
                        >
                          <SelectTrigger>
                            <SelectValue placeholder="Sin categoría" />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="">Sin categoría</SelectItem>
                            {categories.map((categoria) => (
                              <SelectItem key={categoria.id} value={categoria.id}>
                                {categoria.nombre}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />

                <FormField
                  control={form.control}
                  name="disponible"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel>Disponibilidad</FormLabel>
                      <FormControl>
                        <Select
                          value={String(field.value)}
                          onValueChange={(value) => field.onChange(value === "true")}
                        >
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="true">Disponible</SelectItem>
                            <SelectItem value="false">No disponible</SelectItem>
                          </SelectContent>
                        </Select>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </div>

              {!isEditing ? (
                <div className="grid gap-4 sm:grid-cols-2">
                  <FormField
                    control={form.control}
                    name="stockInicial"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Stock inicial</FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            min="0"
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
                    name="stockMinimo"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Stock mínimo</FormLabel>
                        <FormControl>
                          <Input
                            type="number"
                            min="0"
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
              ) : null}

              <div className="space-y-2">
                <Label className="text-sm font-medium">Imagen</Label>
                <div className="flex items-center gap-3">
                  {watchedImageUrl ? (
                    <img
                      src={watchedImageUrl}
                      alt="Vista previa del producto"
                      className="size-20 rounded-md border border-border object-cover"
                    />
                  ) : (
                    <div className="flex size-20 items-center justify-center rounded-md border border-dashed text-muted-foreground text-xs">
                      Sin imagen
                    </div>
                  )}
                  <div className="space-x-2">
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      disabled={uploading}
                      onClick={() => fileInputRef.current?.click()}
                    >
                      {uploading ? <Loader2 className="size-4 animate-spin" /> : null}
                      Subir imagen
                    </Button>
                    {watchedImageUrl ? (
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        onClick={() => form.setValue("imagenUrl", undefined, { shouldDirty: true })}
                      >
                        Quitar
                      </Button>
                    ) : null}
                  </div>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={(event) => void handleFileChange(event.target.files?.[0])}
                  />
                </div>
                <p className="text-muted-foreground text-xs">
                  La imagen se almacena en Supabase Storage mediante la API.
                </p>
              </div>

              <DialogFooter>
                <Button type="button" variant="outline" disabled={isSaving} onClick={() => handleOpenChange(false)}>
                  Cancelar
                </Button>
                <Button type="submit" disabled={isSaving}>
                  {isSaving
                    ? "Guardando…"
                    : isEditing
                      ? "Guardar cambios"
                      : "Crear producto"}
                </Button>
              </DialogFooter>
            </form>
          </Form>

          {isEditing ? (
            <div className="mt-6 space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-medium">Opciones personalizables</h3>
                <span className="text-muted-foreground text-xs">
                  {options.length} opcion(es)
                </span>
              </div>

              <div className="space-y-2">
                {options.map((option) => (
                  <div
                    key={option.id}
                    className={
                      "flex items-center justify-between gap-3 rounded-lg border p-2.5 " +
                      (!option.activo ? "opacity-60" : "")
                    }
                  >
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium">{option.nombre}</p>
                      {option.precioAdicional > 0 ? (
                        <p className="text-muted-foreground text-xs">
                          + {formatCurrency(option.precioAdicional)}
                        </p>
                      ) : (
                        <p className="text-muted-foreground text-xs">Sin costo adicional</p>
                      )}
                    </div>
                    <div className="flex shrink-0 items-center gap-1">
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={optionPendingId === option.id}
                        onClick={() => void handleToggleOption(option)}
                      >
                        {option.activo ? "Desactivar" : "Activar"}
                      </Button>
                      <Button
                        variant="ghost"
                        size="icon"
                        className="text-destructive hover:text-destructive"
                        aria-label={`Eliminar opción ${option.nombre}`}
                        disabled={optionPendingId === option.id}
                        onClick={() => void handleDeleteOption(option)}
                      >
                        <Trash2 className="size-4" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>

              <div className="flex flex-wrap items-center gap-2">
                <Input
                  placeholder="Nombre de la opción"
                  value={optionName}
                  className="flex-1 min-w-40"
                  onChange={(event) => setOptionName(event.target.value)}
                />
                <Input
                  type="number"
                  min="0"
                  step="0.01"
                  placeholder="Precio +"
                  value={optionPrice}
                  className="w-28"
                  onChange={(event) => setOptionPrice(event.target.value)}
                />
                <Button variant="outline" size="sm" onClick={() => void handleAddOption()}>
                  <Plus className="size-4" />
                  Agregar
                </Button>
              </div>
            </div>
          ) : null}
        </div>

        {detailLoading ? (
          <div className="flex items-center justify-center p-6">
            <Loader2 className="size-5 animate-spin text-muted-foreground" />
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  )
}