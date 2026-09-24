import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import {
  getApiV1AdminConfig,
  putApiV1AdminConfigKey,
} from "@/lib/api/generated/admin-config/admin-config"
import type { UpdateConfigRequest } from "@/lib/api/generated/quickBiteAPI.schemas"
import { queryKeys } from "@/lib/api/query-keys"

export interface SystemConfigItem {
  id: string
  clave: string
  valor: string
  descripcion: string | null
  editable: boolean
  creadoEn: string
  actualizadoEn: string
}

export function configValue(
  config: SystemConfigItem[] | undefined,
  clave: string,
): string | undefined {
  return config?.find((item) => item.clave === clave)?.valor
}

export function useSystemConfig() {
  return useQuery({
    queryKey: queryKeys.config.all,
    queryFn: () => getApiV1AdminConfig() as unknown as Promise<SystemConfigItem[]>,
  })
}

export function useUpdateSystemConfig() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ key, value }: { key: string; value: string }) => {
      const request: UpdateConfigRequest = { value }
      return putApiV1AdminConfigKey(key, request)
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.config.all })
    },
  })
}