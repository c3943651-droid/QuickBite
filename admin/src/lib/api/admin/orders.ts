import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import type {
  AssignDeliveryRequest,
  GetApiV1AdminDeliveryPersonsParams,
  GetApiV1AdminOrdersParams,
} from "@/lib/api/generated/quickBiteAPI.schemas"
import {
  getApiV1AdminOrders,
  getApiV1AdminOrdersId,
  patchApiV1AdminOrdersIdAssign,
  patchApiV1AdminOrdersIdCancel,
  patchApiV1AdminOrdersIdStatus,
} from "@/lib/api/generated/admin-orders/admin-orders"
import { getApiV1AdminDeliveryPersons } from "@/lib/api/generated/admin-delivery/admin-delivery"
import { queryKeys } from "@/lib/api/query-keys"
import { usePollingOptions } from "@/hooks/use-polling"

export const ORDER_STATUS_VALUES = {
  Pendiente: 1,
  Confirmado: 2,
  Preparando: 3,
  Listo: 4,
  EnCamino: 5,
  Entregado: 6,
  Cancelado: 7,
} as const

export type OrderStatusValue = (typeof ORDER_STATUS_VALUES)[keyof typeof ORDER_STATUS_VALUES]

export const ORDER_STATUS_LABELS = {
  Pendiente: "Pendiente",
  Confirmado: "Confirmado",
  Preparando: "En preparación",
  Listo: "Listo",
  EnCamino: "En camino",
  Entregado: "Entregado",
  Cancelado: "Cancelado",
} as const

export type OrderStatusLabel = keyof typeof ORDER_STATUS_LABELS

import type { PagedResponse } from "@/lib/api/admin/types"
export type { PagedResponse }

export interface AdminOrderListItem {
  id: string
  numeroPedido: string
  cliente: string
  estado: string
  total: number
  creadoEn: string
  repartidor: string | null
}

export interface AdminOrderItemOption {
  nombre: string
  precioAdicional: number
}

export interface AdminOrderItem {
  id: string
  nombreProducto: string
  precioUnitario: number
  cantidad: number
  observaciones: string | null
  subtotal: number
  opciones: AdminOrderItemOption[]
}

export interface AdminOrderStatusHistory {
  id: string
  estadoAnterior: string | null
  estadoNuevo: string
  usuario: string | null
  comentario: string | null
  creadoEn: string
}

export interface AdminOrderAudit {
  id: string
  accion: string
  usuario: string | null
  ipOrigen: string | null
  creadoEn: string
  detalles: string | null
}

export interface AdminOrderDetail {
  id: string
  numeroPedido: string
  estado: string
  creadoEn: string
  motivoCancelacion: string | null
  clienteNombre: string
  clienteEmail: string | null
  clienteTelefono: string | null
  direccionEntregaSnapshot: string
  repartidorNombre: string | null
  repartidorTelefono: string | null
  repartidorEstado: string | null
  subtotal: number
  costoEnvio: number
  total: number
  items: AdminOrderItem[]
  historialEstados: AdminOrderStatusHistory[]
  auditoria: AdminOrderAudit[]
}

export interface DeliveryPersonListItem {
  usuarioId: string
  nombre: string
  email: string
  telefono: string | null
  estadoDisponibilidad: string
  vehiculo: string | null
  entregasCompletadas: number
  fechaAlta: string
}

export interface AdminOrdersQuery {
  params: GetApiV1AdminOrdersParams
  enabled?: boolean
  intervalMs?: number
}

export function useAdminOrders({ params, enabled = true, intervalMs }: AdminOrdersQuery) {
  const polling = usePollingOptions({ enabled, intervalMs })

  return useQuery({
    queryKey: [...queryKeys.orders.list, params],
    queryFn: () =>
      getApiV1AdminOrders(params) as unknown as Promise<PagedResponse<AdminOrderListItem>>,
    ...polling,
  })
}

export function useAdminOrderDetail(id: string | null | undefined) {
  return useQuery({
    queryKey: queryKeys.orders.detail(id ?? ""),
    enabled: Boolean(id),
    queryFn: () => getApiV1AdminOrdersId(id as string) as unknown as Promise<AdminOrderDetail>,
  })
}

export interface UseAdminDeliveryPersonsQuery {
  params?: GetApiV1AdminDeliveryPersonsParams
  enabled?: boolean
}

export function useAdminDeliveryPersons({
  params = {},
  enabled = true,
}: UseAdminDeliveryPersonsQuery = {}) {
  return useQuery({
    queryKey: [...queryKeys.deliveryPersons.all, params],
    enabled,
    queryFn: () =>
      getApiV1AdminDeliveryPersons(params) as unknown as Promise<
        PagedResponse<DeliveryPersonListItem>
      >,
  })
}

export function useUpdateOrderStatus() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({
      id,
      estado,
      comentario,
    }: {
      id: string
      estado: OrderStatusValue
      comentario?: string | null
    }) => patchApiV1AdminOrdersIdStatus(id, { estado, comentario }),
    onSuccess: (_data, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.orders.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.orders.detail(variables.id) })
      void queryClient.invalidateQueries({ queryKey: queryKeys.dashboard })
    },
  })
}

export function useAssignDeliveryPerson() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, repartidorId }: { id: string; repartidorId: string }) => {
      const body: AssignDeliveryRequest = { repartidorId, origin: 2 }
      return patchApiV1AdminOrdersIdAssign(id, body)
    },
    onSuccess: (_data, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.orders.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.orders.detail(variables.id) })
      void queryClient.invalidateQueries({ queryKey: queryKeys.deliveryPersons.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.dashboard })
    },
  })
}

export function useCancelOrder() {
  const queryClient = useQueryClient()

  return useMutation({
    mutationFn: ({ id, motivo }: { id: string; motivo: string }) =>
      patchApiV1AdminOrdersIdCancel(id, { motivo }),
    onSuccess: (_data, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.orders.all })
      void queryClient.invalidateQueries({ queryKey: queryKeys.orders.detail(variables.id) })
      void queryClient.invalidateQueries({ queryKey: queryKeys.dashboard })
    },
  })
}