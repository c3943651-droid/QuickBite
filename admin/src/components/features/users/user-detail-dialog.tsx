import { useState } from "react"
import { toast } from "sonner"
import { Clock, Mail, Phone, RefreshCw, ShieldAlert } from "lucide-react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { Skeleton } from "@/components/ui/skeleton"
import { StatusChip } from "@/components/common/status-chip"
import { ConfirmDialog } from "@/components/common/confirm-dialog"
import {
  USER_ROLE_LIST,
  useAdminUserDetail,
  useUpdateUserRole,
  useUpdateUserStatus,
} from "@/lib/api/admin/users"
import { getApiErrorMessage } from "@/lib/api/error"
import { useAuth } from "@/lib/session/auth-context"
import { formatDateTime } from "@/lib/format"

export interface UserDetailDialogProps {
  userId: string | null
  onOpenChange: (open: boolean) => void
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

function InfoRow({ icon: Icon, label, value }: {
  icon: typeof Mail
  label: string
  value: string
}) {
  return (
    <div className="flex items-start gap-2">
      <Icon className="mt-0.5 size-4 shrink-0 text-muted-foreground" />
      <div className="min-w-0">
        <p className="text-xs font-medium text-muted-foreground">{label}</p>
        <p className="text-sm break-words">{value || "—"}</p>
      </div>
    </div>
  )
}

export function UserDetailDialog({ userId, onOpenChange }: UserDetailDialogProps) {
  const open = userId !== null
  const { user: currentUser } = useAuth()

  const { data: detail, isLoading, isError } = useAdminUserDetail(userId, { enabled: open })
  const updateRole = useUpdateUserRole()
  const updateStatus = useUpdateUserStatus()
  const [confirmingDeactivate, setConfirmingDeactivate] = useState(false)

  const isSelf = detail?.id != null && detail.id === currentUser?.id

  function handleRoleChange(rol: string) {
    if (!detail || rol === detail.rol) return
    const previous = detail.rol
    void updateRole
      .mutateAsync({ id: detail.id, rol })
      .then(() => toast.success("Rol actualizado"))
      .catch((error) => {
        toast.error(getApiErrorMessage(error, "No se pudo cambiar el rol"))
        return previous
      })
  }

  function handleStatusChange(activo: boolean) {
    if (!detail) return
    if (activo) {
      void updateStatus
        .mutateAsync({ id: detail.id, activo: true })
        .then(() => toast.success(`${detail.nombre} fue reactivado`))
        .catch((error) =>
          toast.error(getApiErrorMessage(error, "No se pudo reactivar al usuario")),
        )
      return
    }
    setConfirmingDeactivate(true)
  }

  async function confirmDeactivate() {
    if (!detail) return
    setConfirmingDeactivate(false)
    try {
      await updateStatus.mutateAsync({ id: detail.id, activo: false })
      toast.success(`${detail.nombre} fue desactivado y sus sesiones cerradas`)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo desactivar al usuario"))
    }
  }

  const mutating = updateRole.isPending || updateStatus.isPending

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          {detail ? (
            <div className="flex flex-wrap items-center gap-3">
              <div className="bg-primary/10 text-primary flex size-10 shrink-0 items-center justify-center rounded-full text-sm font-semibold">
                {initials(detail.nombre)}
              </div>
              <div className="min-w-0">
                <DialogTitle className="flex flex-wrap items-center gap-2">
                  {detail.nombre}
                  <StatusChip status={detail.activo ? "Activo" : "Inactivo"} />
                </DialogTitle>
                <DialogDescription className="mt-0">{detail.email}</DialogDescription>
              </div>
            </div>
          ) : (
            <DialogTitle>Usuario</DialogTitle>
          )}
        </DialogHeader>

        {isLoading ? (
          <div className="space-y-2">
            {Array.from({ length: 4 }).map((_, index) => (
              <Skeleton key={index} className="h-10" />
            ))}
          </div>
        ) : isError || !detail ? (
          <div className="text-muted-foreground py-6 text-center text-sm">
            No se pudo cargar el detalle del usuario.
          </div>
        ) : (
          <div className="space-y-4">
            <section className="grid grid-cols-1 gap-4 rounded-lg border p-4 sm:grid-cols-2">
              <InfoRow icon={Mail} label="Email" value={detail.email} />
              <InfoRow icon={Phone} label="Teléfono" value={detail.telefono ?? ""} />
              <InfoRow
                icon={Clock}
                label="Último acceso"
                value={detail.ultimoLogin ? formatDateTime(detail.ultimoLogin) : "Nunca"}
              />
              <InfoRow icon={Clock} label="Creado" value={formatDateTime(detail.creadoEn)} />
              {detail.vehiculoRepartidor ? (
                <>
                  <InfoRow icon={RefreshCw} label="Vehículo" value={detail.vehiculoRepartidor} />
                  <InfoRow
                    icon={RefreshCw}
                    label="Entregas completadas"
                    value={String(detail.entregasCompletadas)}
                  />
                </>
              ) : null}
            </section>

            <section className="space-y-4 rounded-lg border p-4">
              <h3 className="text-sm font-semibold">Ajustes de cuenta</h3>

              {isSelf ? (
                <div className="bg-muted flex items-start gap-2 rounded-md px-3 py-2 text-sm">
                  <ShieldAlert className="mt-0.5 size-4 shrink-0" />
                  <p className="text-muted-foreground">
                    No puedes cambiar tu rol ni desactivar tu propia cuenta.
                  </p>
                </div>
              ) : null}

              <div className="flex flex-wrap items-center justify-between gap-4">
                <div className="space-y-1">
                  <p className="text-sm font-medium">Rol</p>
                  <p className="text-muted-foreground text-xs">
                    Determina los permisos dentro de la plataforma.
                  </p>
                </div>
                <Select
                  value={detail.rol}
                  onValueChange={handleRoleChange}
                  disabled={isSelf || mutating}
                >
                  <SelectTrigger className="w-44">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {USER_ROLE_LIST.map((role) => (
                      <SelectItem key={role.value} value={role.value}>
                        {role.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="flex flex-wrap items-center justify-between gap-4">
                <div className="space-y-1">
                  <p className="text-sm font-medium">Estado</p>
                  <p className="text-muted-foreground text-xs">
                    Desactivar impide iniciar sesión y cierra las sesiones activas.
                  </p>
                </div>
                <Switch
                  checked={detail.activo}
                  onCheckedChange={handleStatusChange}
                  disabled={isSelf || mutating}
                />
              </div>
            </section>
          </div>
        )}
      </DialogContent>

      <ConfirmDialog
        open={confirmingDeactivate}
        onOpenChange={setConfirmingDeactivate}
        title="Desactivar usuario"
        description={
          detail
            ? `¿Seguro que quieres desactivar a ${detail.nombre}? No podrá iniciar sesión y sus sesiones activas se cerrarán.`
            : undefined
        }
        confirmLabel="Desactivar"
        cancelLabel="Cancelar"
        tone="amber"
        loading={updateStatus.isPending}
        onConfirm={() => void confirmDeactivate()}
      />
    </Dialog>
  )
}