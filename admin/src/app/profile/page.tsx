import { useEffect } from "react"
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { useNavigate } from "react-router-dom"
import { toast } from "sonner"
import { z } from "zod"
import { cn } from "cn"
import {
  KeyRound,
  LogOut,
  Monitor,
  RefreshCw,
  Smartphone,
  UserRound,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Card,
  CardContent,
  CardDescription,
  CardFooter,
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
import { EmptyState } from "@/components/common/empty-state"
import { ErrorState } from "@/components/common/error-state"
import { useAuth } from "@/lib/auth/auth-context"
import { formatDateTime } from "@/lib/format"
import { getApiErrorMessage } from "@/lib/api/error"
import {
  useChangePassword,
  useRevokeOtherSessions,
  useRevokeSession,
  useSessions,
  useUpdateProfile,
  useUserProfile,
  type ActiveSession,
} from "@/lib/api/admin/profile"

const PASSWORD_REGEX = /^(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9\s]).{8,}$/

const profileSchema = z.object({
  nombre: z
    .string()
    .trim()
    .min(2, "Ingresa tu nombre")
    .max(150, "Máximo 150 caracteres"),
  telefono: z
    .string()
    .trim()
    .max(20, "Máximo 20 caracteres")
    .optional()
    .or(z.literal("")),
})

type ProfileValues = z.infer<typeof profileSchema>

const changePasswordSchema = z
  .object({
    currentPassword: z.string().min(1, "Ingresa tu contraseña actual"),
    newPassword: z
      .string()
      .regex(
        PASSWORD_REGEX,
        "Mínimo 8 caracteres, con mayúscula, número y símbolo",
      ),
    confirmPassword: z.string(),
  })
  .refine((values) => values.newPassword === values.confirmPassword, {
    message: "Las contraseñas no coinciden",
    path: ["confirmPassword"],
  })

type ChangePasswordValues = z.infer<typeof changePasswordSchema>

const DEFAULT_PROFILE: ProfileValues = { nombre: "", telefono: "" }

function deviceLabel(session: ActiveSession): string {
  if (!session.user_agent) return "Dispositivo desconocido"
  const name = /iPhone|iPad/i.test(session.user_agent)
    ? "iPhone/iPad"
    : /Android/i.test(session.user_agent)
      ? "Dispositivo Android"
      : /Windows/i.test(session.user_agent)
        ? "Windows"
        : /Macintosh/i.test(session.user_agent)
          ? "Mac"
          : /Linux/i.test(session.user_agent)
            ? "Linux"
            : "Navegador"
  return session.user_agent.includes("Mobile") ? `${name} (móvil)` : name
}

function initials(name: string | undefined): string {
  const parts = (name ?? "?").trim().split(/\s+/)
  const first = parts[0]?.[0] ?? "?"
  const last = parts[1]?.[0]
  return last ? `${first}${last}`.toUpperCase() : first.toUpperCase()
}

export default function ProfilePage() {
  const { user, logout, patchUser } = useAuth()
  const navigate = useNavigate()
  const {
    data: profile,
    isLoading,
    isRefetching,
    isError,
    refetch,
  } = useUserProfile()
  const updateProfile = useUpdateProfile()
  const changePassword = useChangePassword()
  const {
    data: sessions = [],
    isLoading: sessionsLoading,
    isError: sessionsError,
    refetch: refetchSessions,
  } = useSessions()
  const revokeSession = useRevokeSession()
  const revokeOthers = useRevokeOtherSessions()

  const profileForm = useForm<ProfileValues>({
    resolver: zodResolver(profileSchema),
    defaultValues: DEFAULT_PROFILE,
  })

  const passwordForm = useForm<ChangePasswordValues>({
    resolver: zodResolver(changePasswordSchema),
    defaultValues: {
      currentPassword: "",
      newPassword: "",
      confirmPassword: "",
    },
  })

  useEffect(() => {
    if (profile) {
      profileForm.reset({
        nombre: profile.nombre,
        telefono: profile.telefono ?? "",
      })
    }
  }, [profile, profileForm])

  async function onSaveProfile(values: ProfileValues) {
    try {
      await updateProfile.mutateAsync({
        nombre: values.nombre,
        telefono: values.telefono || undefined,
      })
      patchUser({ nombre: values.nombre })
      toast.success("Perfil actualizado correctamente")
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo actualizar el perfil"))
    }
  }

  async function onChangePassword(values: ChangePasswordValues) {
    try {
      await changePassword.mutateAsync({
        currentPassword: values.currentPassword,
        newPassword: values.newPassword,
      })
      toast.success("Contraseña actualizada correctamente")
      passwordForm.reset()
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo cambiar la contraseña"))
    }
  }

  async function onLogout() {
    try {
      await logout()
    } finally {
      navigate("/login", { replace: true })
    }
  }

  async function onRevoke(id: string) {
    try {
      await revokeSession.mutateAsync(id)
      toast.success("Sesión revocada")
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo revocar la sesión"))
    }
  }

  async function onRevokeOthers() {
    const others = sessions.filter((session) => !session.es_actual)
    try {
      await revokeOthers.mutateAsync(others.map((session) => session.id))
      toast.success("Sesiones cerradas en otros dispositivos")
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudieron cerrar las sesiones"))
    }
  }

  const isBusy = isRefetching
  const revokedPending = revokeSession.isPending || revokeOthers.isPending

  if (isError) {
    return (
      <ErrorState
        title="No se pudo cargar tu perfil"
        description="Revisa tu conexión o intenta nuevamente."
        onRetry={() => void refetch()}
      />
    )
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Perfil</h1>
          <p className="text-muted-foreground text-sm">
            Tu información personal, seguridad y sesiones activas.
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
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
          <Card>
            <div className="h-64 animate-pulse rounded-lg bg-muted/60" />
          </Card>
          <Card>
            <div className="h-64 animate-pulse rounded-lg bg-muted/60" />
          </Card>
        </div>
      ) : (
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
          <Form {...profileForm}>
            <form
              onSubmit={(event) => void profileForm.handleSubmit(onSaveProfile)(event)}
              className="contents"
            >
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <UserRound className="size-4" />
                    Datos personales
                  </CardTitle>
                  <CardDescription>
                    Información básica de tu cuenta de administrador.
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <div className="flex items-center gap-3 rounded-md border bg-muted/40 p-3">
                    <div className="flex size-10 shrink-0 items-center justify-center rounded-full bg-primary/10 text-sm font-semibold text-primary">
                      {initials(user?.nombre)}
                    </div>
                    <div className="min-w-0">
                      <p className="truncate text-sm font-medium">{profile?.email}</p>
                      <p className="text-muted-foreground text-xs">
                        Correo de acceso, no editable
                      </p>
                    </div>
                  </div>
                  <FormField
                    control={profileForm.control}
                    name="nombre"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Nombre</FormLabel>
                        <FormControl>
                          <Input {...field} disabled={isBusy} autoComplete="name" />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={profileForm.control}
                    name="telefono"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Teléfono</FormLabel>
                        <FormControl>
                          <Input
                            type="tel"
                            placeholder="Opcional"
                            {...field}
                            disabled={isBusy}
                            autoComplete="tel"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </CardContent>
                <CardFooter>
                  <Button type="submit" disabled={updateProfile.isPending || isBusy}>
                    {updateProfile.isPending ? "Guardando…" : "Guardar cambios"}
                  </Button>
                </CardFooter>
              </Card>
            </form>
          </Form>

          <Form {...passwordForm}>
            <form
              onSubmit={(event) =>
                void passwordForm.handleSubmit(onChangePassword)(event)
              }
              className="contents"
            >
              <Card>
                <CardHeader>
                  <CardTitle className="flex items-center gap-2">
                    <KeyRound className="size-4" />
                    Cambiar contraseña
                  </CardTitle>
                  <CardDescription>
                    Actualiza tu contraseña para mantener tu cuenta segura.
                  </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                  <FormField
                    control={passwordForm.control}
                    name="currentPassword"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Contraseña actual</FormLabel>
                        <FormControl>
                          <Input
                            type="password"
                            {...field}
                            autoComplete="current-password"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={passwordForm.control}
                    name="newPassword"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Nueva contraseña</FormLabel>
                        <FormControl>
                          <Input
                            type="password"
                            {...field}
                            autoComplete="new-password"
                          />
                        </FormControl>
                        <FormDescription>
                          Mínimo 8 caracteres, con mayúscula, número y símbolo.
                        </FormDescription>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                  <FormField
                    control={passwordForm.control}
                    name="confirmPassword"
                    render={({ field }) => (
                      <FormItem>
                        <FormLabel>Confirmar contraseña</FormLabel>
                        <FormControl>
                          <Input
                            type="password"
                            {...field}
                            autoComplete="new-password"
                          />
                        </FormControl>
                        <FormMessage />
                      </FormItem>
                    )}
                  />
                </CardContent>
                <CardFooter>
                  <Button type="submit" disabled={changePassword.isPending}>
                    {changePassword.isPending
                      ? "Actualizando…"
                      : "Actualizar contraseña"}
                  </Button>
                </CardFooter>
              </Card>
            </form>
          </Form>
        </div>
      )}

      <Card>
        <CardHeader className="flex flex-row items-start justify-between gap-3">
          <div>
            <CardTitle className="flex items-center gap-2">
              <Monitor className="size-4" />
              Sesiones activas
            </CardTitle>
            <CardDescription>
              Dispositivos conectados a tu cuenta de QuickBite.
            </CardDescription>
          </div>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={
                revokedPending ||
                sessionsError ||
                sessions.filter((session) => !session.es_actual).length === 0
              }
              onClick={() => void onRevokeOthers()}
            >
              {revokeOthers.isPending ? "Cerrando…" : "Cerrar las demás"}
            </Button>
            <Button
              variant="ghost"
              size="sm"
              className="text-destructive hover:text-destructive"
              onClick={() => void onLogout()}
            >
              <LogOut className="mr-1.5 size-4" />
              Cerrar sesión
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          {sessionsLoading ? (
            <div className="space-y-3">
              <div className="h-16 animate-pulse rounded-lg bg-muted/60" />
              <div className="h-16 animate-pulse rounded-lg bg-muted/60" />
            </div>
          ) : sessionsError ? (
            <ErrorState
              title="No se pudieron cargar las sesiones"
              description="Revisa tu conexión o intenta nuevamente."
              onRetry={() => void refetchSessions()}
            />
          ) : sessions.length === 0 ? (
            <EmptyState
              icon={Smartphone}
              title="Sin sesiones activas"
              description="No hay dispositivos conectados a tu cuenta."
            />
          ) : (
            <ul className="space-y-3">
              {sessions.map((session) => {
                const current = session.es_actual
                return (
                  <li
                    key={session.id}
                    className="flex flex-wrap items-center justify-between gap-3 rounded-lg border p-3"
                  >
                    <div className="flex min-w-0 items-center gap-3">
                      <div className="flex size-9 shrink-0 items-center justify-center rounded-full bg-muted">
                        <Monitor className="size-4 text-muted-foreground" />
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-2">
                          <p className="truncate text-sm font-medium">
                            {deviceLabel(session)}
                          </p>
                          {current ? (
                            <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-xs font-medium text-green-800 dark:bg-green-500/15 dark:text-green-300">
                              <span className="size-1.5 rounded-full bg-current opacity-70" />
                              Esta sesión
                            </span>
                          ) : null}
                        </div>
                        <p className="text-muted-foreground text-xs">
                          {session.ip_origen ?? "IP no registrada"} · Iniciada el{" "}
                          {formatDateTime(session.creado_en)} · Expira el{" "}
                          {formatDateTime(session.expira_en)}
                        </p>
                      </div>
                    </div>
                    {!current ? (
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={revokedPending}
                        onClick={() => void onRevoke(session.id)}
                      >
                        Revocar
                      </Button>
                    ) : null}
                  </li>
                )
              })}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  )
}