import { useEffect, useMemo, useState } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { toast } from "sonner"
import { z } from "zod"
import { cn } from "cn"
import { AlarmClock, RefreshCw, Store, TriangleAlert } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Switch } from "@/components/ui/switch"
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form"
import { ErrorState } from "@/components/common/error-state"
import {
  configValue,
  useSystemConfig,
  useUpdateSystemConfig,
  type SystemConfigItem,
} from "@/lib/api/admin/config"
import { getApiErrorMessage } from "@/lib/api/error"

const STATE_KEYS = ["restaurante_abierto", "horario_apertura", "horario_cierre"]

const NUMERIC_KEYS: Record<string, { step: string; suffix?: string }> = {
  tiempo_preparacion_estimado: { step: "1", suffix: "min" },
  tiempo_entrega_estimado: { step: "1", suffix: "min" },
  carrito_expiracion_horas: { step: "1", suffix: "h" },
  max_intentos_login: { step: "1" },
  costo_envio_default: { step: "0.01", suffix: "MXN" },
}

const configFormSchema = z.object({
  abierto: z.boolean(),
  horarioApertura: z
    .string()
    .regex(/^([01]\d|2[0-3]):[0-5]\d$/, "Formato HH:MM requerido"),
  horarioCierre: z
    .string()
    .regex(/^([01]\d|2[0-3]):[0-5]\d$/, "Formato HH:MM requerido"),
  parametros: z.record(z.string(), z.string().min(1, "El valor no puede estar vacío")),
})

type ConfigFormValues = z.infer<typeof configFormSchema>

function buildDefaults(config: SystemConfigItem[]): ConfigFormValues {
  return {
    abierto: configValue(config, "restaurante_abierto") !== "false",
    horarioApertura: configValue(config, "horario_apertura") ?? "09:00",
    horarioCierre: configValue(config, "horario_cierre") ?? "22:00",
    parametros: Object.fromEntries(
      config
        .filter((item) => item.editable && !STATE_KEYS.includes(item.clave))
        .map((item) => [item.clave, item.valor]),
    ),
  }
}

export default function ConfigPage() {
  const { data, isLoading, isRefetching, isError, refetch } = useSystemConfig()
  const updateConfig = useUpdateSystemConfig()
  const [saving, setSaving] = useState(false)

  const form = useForm<ConfigFormValues>({
    resolver: zodResolver(configFormSchema),
    defaultValues: { abierto: true, horarioApertura: "09:00", horarioCierre: "22:00", parametros: {} },
  })

  useEffect(() => {
    if (data) form.reset(buildDefaults(data))
  }, [data, form])

  const original = useMemo(() => {
    const params = new Map<string, string>()
    for (const item of data ?? []) {
      if (item.editable) params.set(item.clave, item.valor)
    }
    return params
  }, [data])

  const missingStateKeys = useMemo(() => {
    const present = new Set((data ?? []).map((item) => item.clave))
    return STATE_KEYS.filter((key) => !present.has(key))
  }, [data])

  const paramItems = useMemo(
    () =>
      (data ?? []).filter(
        (item) => item.editable && !STATE_KEYS.includes(item.clave),
      ),
    [data],
  )

  async function onSubmit(values: ConfigFormValues) {
    const entries: Array<{ key: string; value: string }> = []
    const originalAbierto = (original.get("restaurante_abierto") ?? "true") !== "false"
    if (values.abierto !== originalAbierto)
      entries.push({ key: "restaurante_abierto", value: String(values.abierto) })
    if (values.horarioApertura !== (original.get("horario_apertura") ?? "09:00"))
      entries.push({ key: "horario_apertura", value: values.horarioApertura })
    if (values.horarioCierre !== (original.get("horario_cierre") ?? "22:00"))
      entries.push({ key: "horario_cierre", value: values.horarioCierre })
    for (const [clave, valor] of Object.entries(values.parametros)) {
      if (valor !== original.get(clave)) entries.push({ key: clave, value: valor })
    }

    if (entries.length === 0) {
      toast.info("No hay cambios por guardar")
      return
    }

    setSaving(true)
    try {
      for (const entry of entries) {
        await updateConfig.mutateAsync(entry)
      }
      toast.success("Configuración guardada")
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo guardar la configuración"))
    } finally {
      setSaving(false)
    }
  }

  const isBusy = saving || isRefetching

  if (isError) {
    return (
      <ErrorState
        title="No se pudo cargar la configuración"
        description="Revisa tu conexión o intenta nuevamente."
        onRetry={() => void refetch()}
      />
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Configuración</h1>
          <p className="text-muted-foreground text-sm">
            Ajustes del restaurante y preferencias de la plataforma.
          </p>
        </div>
        <Button
          variant="outline"
          size="sm"
          disabled={isBusy}
          onClick={() => void refetch()}
        >
          <RefreshCw className={cn("size-4", isRefetching && "animate-spin")} />
          Recargar
        </Button>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
          <Card className="xl:col-span-1">
            <div className="h-64 animate-pulse rounded-lg bg-muted/60" />
          </Card>
          <Card className="xl:col-span-2">
            <div className="h-64 animate-pulse rounded-lg bg-muted/60" />
          </Card>
        </div>
      ) : missingStateKeys.length > 0 ? (
        <div className="flex items-start gap-3 rounded-md border border-amber-300 bg-amber-50 p-4 text-sm text-amber-800 dark:border-amber-500/40 dark:bg-amber-500/10 dark:text-amber-300">
          <TriangleAlert className="mt-0.5 size-4 shrink-0" />
          <p>
            El backend no tiene configuradas las claves {missingStateKeys.join(", ")}. Los
            valores de estado y horario se guardarán al añadirlas a la tabla
            configuracion_sistema.
          </p>
        </div>
      ) : null}

      <Form {...form}>
        <form
          onSubmit={(event) => void form.handleSubmit(onSubmit)(event)}
          className="space-y-6"
        >
          <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
            <Card className="xl:col-span-1">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Store className="size-4" />
                  Estado del restaurante
                </CardTitle>
                <CardDescription>
                  Abre o cierra el negocio y define el horario de atención.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <FormField
                  control={form.control}
                  name="abierto"
                  render={({ field }) => (
                    <FormItem className="flex items-center justify-between gap-4">
                      <div className="space-y-0.5">
                        <FormLabel>Restaurante abierto</FormLabel>
                        <FormDescription>
                          {field.value ? "Recibiendo pedidos" : "Pedidos suspendidos"}
                        </FormDescription>
                      </div>
                      <FormControl>
                        <Switch
                          checked={field.value}
                          onCheckedChange={field.onChange}
                          disabled={isBusy}
                        />
                      </FormControl>
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="horarioApertura"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="flex items-center gap-1.5">
                        <AlarmClock className="size-3.5" />
                        Apertura
                      </FormLabel>
                      <FormControl>
                        <Input
                          type="time"
                          {...field}
                          onChange={(event) => field.onChange(event.target.value)}
                          disabled={isBusy}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
                <FormField
                  control={form.control}
                  name="horarioCierre"
                  render={({ field }) => (
                    <FormItem>
                      <FormLabel className="flex items-center gap-1.5">
                        <AlarmClock className="size-3.5" />
                        Cierre
                      </FormLabel>
                      <FormControl>
                        <Input
                          type="time"
                          {...field}
                          onChange={(event) => field.onChange(event.target.value)}
                          disabled={isBusy}
                        />
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )}
                />
              </CardContent>
            </Card>

            <Card className="xl:col-span-2">
              <CardHeader>
                <CardTitle>Parámetros del negocio</CardTitle>
                <CardDescription>
                  Valores que aplican al proceso de pedidos y a la plataforma.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {paramItems.length === 0 ? (
                  <p className="text-muted-foreground text-sm">
                    No hay parámetros editables configurados.
                  </p>
                ) : (
                  paramItems.map((item) => {
                    const numConfig = NUMERIC_KEYS[item.clave]
                    const label = item.descripcion ?? item.clave
                    return (
                      <FormField
                        key={item.clave}
                        control={form.control}
                        name={`parametros.${item.clave}`}
                        render={({ field }) => (
                          <FormItem>
                            <FormLabel>{label}</FormLabel>
                            <FormControl>
                              <div className="flex items-center gap-2">
                                <Input
                                  type={numConfig ? "number" : "text"}
                                  step={numConfig?.step}
                                  inputMode={numConfig ? "numeric" : undefined}
                                  {...field}
                                  onChange={(event) => field.onChange(event.target.value)}
                                  disabled={isBusy}
                                  className="max-w-xs"
                                />
                                {numConfig?.suffix ? (
                                  <span className="text-sm text-muted-foreground">
                                    {numConfig.suffix}
                                  </span>
                                ) : null}
                              </div>
                            </FormControl>
                            <FormMessage />
                          </FormItem>
                        )}
                      />
                    )
                  })
                )}
              </CardContent>
            </Card>
          </div>

          <div className="flex justify-end">
            <Button type="submit" disabled={isBusy || !data}>
              {saving ? "Guardando…" : "Guardar cambios"}
            </Button>
          </div>
        </form>
      </Form>
    </div>
  )
}