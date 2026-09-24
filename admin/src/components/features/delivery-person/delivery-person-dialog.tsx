import { useEffect } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { toast } from "sonner"
import { z } from "zod"
import { cn } from "cn"
import { Bike, CheckCircle2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
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
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { ErrorState } from "@/components/common/error-state"
import type { DeliveryPersonListItem } from "@/lib/api/admin/orders"
import {
  DELIVERY_PERSON_STATUS_LIST,
  deliveryPersonStatusLabel,
  useAvailableDeliveryUsers,
  useCreateDeliveryPerson,
  useUpdateDeliveryPerson,
  type DeliveryPersonStatusValue,
} from "@/lib/api/admin/delivery-persons"
import { getApiErrorMessage } from "@/lib/api/error"

const deliveryPersonFormSchema = z.object({
  usuarioId: z.string({ error: "Selecciona un usuario" }).min(1, "Selecciona un usuario"),
  vehiculo: z.string().trim().max(80, "Máximo 80 caracteres"),
  estadoDisponibilidad: z.enum(["disponible", "ocupado", "inactivo"]),
})

type DeliveryPersonFormValues = z.infer<typeof deliveryPersonFormSchema>

const EMPTY_VALUES: DeliveryPersonFormValues = {
  usuarioId: "",
  vehiculo: "",
  estadoDisponibilidad: "inactivo",
}

export interface DeliveryPersonDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  repartidor: DeliveryPersonListItem | null
}

export function DeliveryPersonDialog({
  open,
  onOpenChange,
  repartidor,
}: DeliveryPersonDialogProps) {
  const isEditing = repartidor !== null
  const createDeliveryPerson = useCreateDeliveryPerson()
  const updateDeliveryPerson = useUpdateDeliveryPerson()
  const isPending = createDeliveryPerson.isPending || updateDeliveryPerson.isPending

  const availableUsers = useAvailableDeliveryUsers()

  const hasActiveDeliveries = isEditing && repartidor.estadoDisponibilidad === "ocupado"

  const form = useForm<DeliveryPersonFormValues>({
    resolver: zodResolver(deliveryPersonFormSchema),
    defaultValues: EMPTY_VALUES,
  })

  useEffect(() => {
    if (!open) return
    const initial: DeliveryPersonFormValues = isEditing
      ? {
          usuarioId: repartidor.usuarioId,
          vehiculo: repartidor.vehiculo ?? "",
          estadoDisponibilidad: isDeliveryPersonStatus(repartidor.estadoDisponibilidad)
            ? repartidor.estadoDisponibilidad
            : "inactivo",
        }
      : EMPTY_VALUES
    form.reset(initial)
  }, [open, isEditing, repartidor, form])

  async function onSubmit(values: DeliveryPersonFormValues) {
    try {
      if (isEditing) {
        await updateDeliveryPerson.mutateAsync({
          id: repartidor.usuarioId,
          body: {
            vehiculo: values.vehiculo || null,
            estadoDisponibilidad: values.estadoDisponibilidad,
          },
        })
        toast.success("Repartidor actualizado")
      } else {
        await createDeliveryPerson.mutateAsync({
          usuarioId: values.usuarioId,
          vehiculo: values.vehiculo || null,
        })
        toast.success("Repartidor creado (inicia inactivo)")
      }
      onOpenChange(false)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo guardar el repartidor"))
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{isEditing ? "Editar repartidor" : "Nuevo repartidor"}</DialogTitle>
          <DialogDescription>
            {isEditing
              ? "Actualiza el vehículo o la disponibilidad del repartidor."
              : "Registra un usuario con rol repartidor en el equipo."}
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={(event) => void form.handleSubmit(onSubmit)(event)} className="space-y-4">
            {isEditing ? (
              <FormItem>
                <FormLabel>Repartidor</FormLabel>
                <FormControl>
                  <div className="flex min-w-0 items-center gap-3 rounded-md border p-3">
                    <div className="bg-primary/10 text-primary flex size-9 shrink-0 items-center justify-center rounded-full text-xs font-semibold">
                      {initials(repartidor.nombre)}
                    </div>
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium">{repartidor.nombre}</p>
                      <p className="truncate text-muted-foreground text-xs">{repartidor.email}</p>
                    </div>
                    <p className="ml-auto shrink-0 text-xs text-muted-foreground">
                      {deliveryPersonStatusLabel(repartidor.estadoDisponibilidad)}
                    </p>
                  </div>
                </FormControl>
              </FormItem>
            ) : (
              <FormField
                control={form.control}
                name="usuarioId"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Usuario</FormLabel>
                    <FormControl>
                      <div className="max-h-44 space-y-2 overflow-y-auto pr-1">
                        {availableUsers.isLoading ? (
                          <div className="space-y-2">
                            {Array.from({ length: 3 }).map((_, i) => (
                              <div
                                key={i}
                                className="h-12 animate-pulse rounded-md bg-muted"
                              />
                            ))}
                          </div>
                        ) : availableUsers.isError ? (
                          <ErrorState
                            title="No se pudieron cargar los usuarios"
                            onRetry={() => void availableUsers.refetch()}
                          />
                        ) : (availableUsers.data ?? []).length === 0 ? (
                          <p className="rounded-md border border-dashed p-3 text-sm text-muted-foreground">
                            No hay usuarios con rol repartidor pendientes de registrar.
                          </p>
                        ) : (
                          availableUsers.data?.map((candidate) => {
                            const selected = field.value === candidate.usuarioId
                            return (
                              <button
                                key={candidate.usuarioId}
                                type="button"
                                className={cn(
                                  "flex w-full items-center justify-between gap-3 rounded-md border p-2.5 text-left transition-colors hover:border-primary/50",
                                  selected && "border-primary bg-primary/5",
                                )}
                                onClick={() => field.onChange(candidate.usuarioId)}
                              >
                                <span className="min-w-0">
                                  <span className="block truncate text-sm font-medium">
                                    {candidate.nombre}
                                  </span>
                                  <span className="block truncate text-xs text-muted-foreground">
                                    {candidate.email}
                                  </span>
                                </span>
                                {selected ? (
                                  <CheckCircle2 className="size-4 shrink-0 text-primary" />
                                ) : null}
                              </button>
                            )
                          })
                        )}
                      </div>
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
            )}

            <FormField
              control={form.control}
              name="vehiculo"
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Vehículo</FormLabel>
                  <FormControl>
                    <Input
                      placeholder="Ej. Moto Honda 125 · ABC-123"
                      {...field}
                      onChange={(event) => field.onChange(event.target.value)}
                    />
                  </FormControl>
                  <FormDescription>Marca, modelo o matrícula (opcional).</FormDescription>
                  <FormMessage />
                </FormItem>
              )}
            />

            {isEditing ? (
              <FormField
                control={form.control}
                name="estadoDisponibilidad"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Estado de disponibilidad</FormLabel>
                    <FormControl>
                      <Select
                        value={field.value}
                        onValueChange={(value) => field.onChange(value as DeliveryPersonStatusValue)}
                      >
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {DELIVERY_PERSON_STATUS_LIST.map((status) => (
                            <SelectItem
                              key={status.value}
                              value={status.value}
                              disabled={hasActiveDeliveries && status.value !== "ocupado"}
                            >
                              {status.label}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </FormControl>
                    {hasActiveDeliveries ? (
                      <FormDescription>
                        <Bike className="mr-1 inline size-3.5" />
                        No puede dejar de estar &quot;En entrega&quot; mientras tenga pedidos
                        activos.
                      </FormDescription>
                    ) : null}
                    <FormMessage />
                  </FormItem>
                )}
              />
            ) : null}

            <DialogFooter>
              <Button
                type="button"
                variant="outline"
                disabled={isPending}
                onClick={() => onOpenChange(false)}
              >
                Cancelar
              </Button>
              <Button type="submit" disabled={isPending}>
                {isPending
                  ? "Guardando…"
                  : isEditing
                    ? "Guardar cambios"
                    : "Registrar repartidor"}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  )
}

function isDeliveryPersonStatus(value: string): value is DeliveryPersonStatusValue {
  return value === "disponible" || value === "ocupado" || value === "inactivo"
}

function initials(nombre: string): string {
  return nombre
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase()
}