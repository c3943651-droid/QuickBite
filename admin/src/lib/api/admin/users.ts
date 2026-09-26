import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import type {
  GetApiV1AdminUsersParams,
  UpdateUserRoleRequest,
  UpdateUserStatusRequest,
} from "@/lib/api/generated/quickBiteAPI.schemas"
import {
  getApiV1AdminUsers,
  getApiV1AdminUsersId,
  putApiV1AdminUsersIdRole,
  putApiV1AdminUsersIdStatus,
} from "@/lib/api/generated/admin-user/admin-user"
import { queryKeys } from "@/lib/api/query-keys"
import type { PagedResponse } from "@/lib/api/admin/types"

export const USER_ROLE_MAP = {
  cliente: { label: "Cliente", value: "cliente" },
  administrador: { label: "Administrador", value: "administrador" },
  repartidor: { label: "Repartidor", value: "repartidor" },
} as const

export type UserRoleValue = keyof typeof USER_ROLE_MAP

export const USER_ROLE_LIST = Object.values(USER_ROLE_MAP)

export function userRoleLabel(rol: string): string {
  return USER_ROLE_MAP[rol as UserRoleValue]?.label ?? rol
}

export interface AdminUserListItem {
  id: string
  nombre: string
  email: string
  telefono: string | null
  rol: string
  activo: boolean
  ultimoLogin: string | null
  creadoEn: string
}

export interface AdminUserDetail extends AdminUserListItem {
  actualizadoEn: string
  intentosFallidos: number
  bloqueadoHasta: string | null
  vehiculoRepartidor: string | null
  entregasCompletadas: number
}

export interface UseAdminUsersQuery {
  params?: GetApiV1AdminUsersParams
  enabled?: boolean
}

export function useAdminUsers({ params = {}, enabled = true }: UseAdminUsersQuery = {}) {
  return useQuery({
    queryKey: [...queryKeys.users.all, params],
    enabled,
    queryFn: () =>
      getApiV1AdminUsers(params) as unknown as Promise<PagedResponse<AdminUserListItem>>,
  })
}

export function useAdminUserDetail(
  id: string | null | undefined,
  { enabled = true }: { enabled?: boolean } = {},
) {
  return useQuery({
    queryKey: queryKeys.users.detail(id ?? ""),
    enabled: Boolean(id) && enabled,
    queryFn: () => getApiV1AdminUsersId(id as string) as unknown as Promise<AdminUserDetail>,
  })
}

export function useUpdateUserRole() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, rol }: { id: string; rol: string }) => {
      const body: UpdateUserRoleRequest = { rol }
      return putApiV1AdminUsersIdRole(id, body) as unknown as Promise<AdminUserDetail>
    },
    onSuccess: (_data, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.users.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.users.detail(variables.id) })
    },
  })
}

export function useUpdateUserStatus() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, activo }: { id: string; activo: boolean }) => {
      const body: UpdateUserStatusRequest = { activo }
      return putApiV1AdminUsersIdStatus(id, body) as unknown as Promise<AdminUserDetail>
    },
    onSuccess: (_data, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.users.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.users.detail(variables.id) })
    },
  })
}