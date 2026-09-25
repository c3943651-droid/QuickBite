import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import { deleteApiV1UsersSessionsId } from "@/lib/api/generated/users/users"
import type {
  ChangePasswordRequest,
  UpdateProfileRequest,
} from "@/lib/api/generated/quickBiteAPI.schemas"
import { queryKeys } from "@/lib/api/query-keys"
import { getRefreshToken } from "@/lib/session/storage"
import { customInstance } from "@/lib/api/custom-instance"

export interface UserProfile {
  id: string
  nombre: string
  email: string
  telefono: string | null
  rol: string
  creado_en: string
  ultimo_login: string | null
}

export interface ActiveSession {
  id: string
  ip_origen: string | null
  user_agent: string | null
  creado_en: string
  expira_en: string
  es_actual: boolean
}

export function useUserProfile() {
  return useQuery({
    queryKey: queryKeys.profile.all,
    queryFn: () =>
      customInstance<UserProfile>({ url: "/api/v1/users/profile", method: "GET" }),
  })
}

export function useUpdateProfile() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ nombre, telefono }: { nombre: string; telefono?: string }) => {
      const request: UpdateProfileRequest = { nombre, telefono: telefono || null }
      return customInstance<void>({
        url: "/api/v1/users/profile",
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        data: request,
      })
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.profile.all })
    },
  })
}

export function useChangePassword() {
  return useMutation({
    mutationFn: ({
      currentPassword,
      newPassword,
    }: {
      currentPassword: string
      newPassword: string
    }) => {
      const request: ChangePasswordRequest = {
        currentPassword,
        newPassword,
      }
      return customInstance<void>({
        url: "/api/v1/users/change-password",
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        data: request,
      })
    },
  })
}

export function useSessions() {
  return useQuery({
    queryKey: queryKeys.profile.sessions,
    queryFn: () => {
      const refreshToken = getRefreshToken()
      return customInstance<ActiveSession[]>({
        url: "/api/v1/users/sessions",
        method: "GET",
        headers: refreshToken ? { "X-Refresh-Token": refreshToken } : undefined,
      })
    },
  })
}

export function useRevokeSession() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (id: string) => deleteApiV1UsersSessionsId(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.profile.sessions })
    },
  })
}

export function useRevokeOtherSessions() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: async (ids: string[]) => {
      await Promise.all(ids.map((id) => deleteApiV1UsersSessionsId(id)))
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.profile.sessions })
    },
  })
}