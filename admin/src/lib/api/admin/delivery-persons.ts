import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import type {
  CreateDeliveryPersonRequest,
  GetApiV1AdminDeliveryPersonsIdHistoryParams,
  UpdateDeliveryPersonRequest,
} from "@/lib/api/generated/quickBiteAPI.schemas"
import {
  getApiV1AdminDeliveryPersonsAvailableUsers,
  getApiV1AdminDeliveryPersonsIdHistory,
  patchApiV1AdminDeliveryPersonsIdDeactivate,
  postApiV1AdminDeliveryPersons,
  putApiV1AdminDeliveryPersonsId,
} from "@/lib/api/generated/admin-delivery/admin-delivery"
import { queryKeys } from "@/lib/api/query-keys"
import type { DeliveryPersonListItem } from "@/lib/api/admin/orders"
import type { PagedResponse } from "@/lib/api/admin/types"

export const DELIVERY_PERSON_STATUS_MAP = {
  disponible: { label: "Disponible", value: "disponible" },
  ocupado: { label: "En entrega", value: "ocupado" },
  inactivo: { label: "Inactivo", value: "inactivo" },
} as const

export type DeliveryPersonStatusValue = keyof typeof DELIVERY_PERSON_STATUS_MAP

export const DELIVERY_PERSON_STATUS_LIST = Object.values(DELIVERY_PERSON_STATUS_MAP)

export function deliveryPersonStatusLabel(estado: string): string {
  return DELIVERY_PERSON_STATUS_MAP[estado as DeliveryPersonStatusValue]?.label ?? estado
}

export interface DeliveryPersonHistoryEntry {
  numeroPedido: string
  cliente: string
  total: number
  entregadoEn: string | null
  tiempoEntregaMinutos: number | null
}

export interface DeliveryUserCandidate {
  usuarioId: string
  nombre: string
  email: string
}

export function useDeliveryPersonHistory(
  id: string | null | undefined,
  params?: GetApiV1AdminDeliveryPersonsIdHistoryParams,
) {
  return useQuery({
    queryKey: [...queryKeys.deliveryPersons.history(id ?? ""), params],
    enabled: Boolean(id),
    queryFn: () =>
      getApiV1AdminDeliveryPersonsIdHistory(
        id as string,
        params,
      ) as unknown as Promise<PagedResponse<DeliveryPersonHistoryEntry>>,
  })
}

export function useAvailableDeliveryUsers() {
  return useQuery({
    queryKey: queryKeys.deliveryPersons.availableUsers,
    queryFn: () =>
      getApiV1AdminDeliveryPersonsAvailableUsers() as unknown as Promise<DeliveryUserCandidate[]>,
  })
}

export function useCreateDeliveryPerson() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (body: CreateDeliveryPersonRequest) => postApiV1AdminDeliveryPersons(body),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.deliveryPersons.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.deliveryPersons.availableUsers })
    },
  })
}

export function useUpdateDeliveryPerson() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      id,
      body,
    }: {
      id: string
      body: UpdateDeliveryPersonRequest
    }) => putApiV1AdminDeliveryPersonsId(id, body) as unknown as Promise<DeliveryPersonListItem>,
    onSuccess: (_data, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.deliveryPersons.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.deliveryPersons.detail(variables.id) })
      void queryClient.invalidateQueries({
        queryKey: queryKeys.deliveryPersons.history(variables.id),
      })
    },
  })
}

export function useDeactivateDeliveryPerson() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: (id: string) => patchApiV1AdminDeliveryPersonsIdDeactivate(id),
    onSuccess: (_data, id) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.deliveryPersons.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.deliveryPersons.detail(id) })
    },
  })
}