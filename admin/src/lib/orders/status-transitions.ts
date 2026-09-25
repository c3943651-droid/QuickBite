import {
  ORDER_STATUS_VALUES,
  type OrderStatusValue,
} from "@/lib/api/admin/orders"

export interface Transition {
  label: string
  value: OrderStatusValue
}

export const NEXT_TRANSITIONS: Partial<Record<string, Transition>> = {
  Pendiente: { label: "Confirmar", value: ORDER_STATUS_VALUES.Confirmado },
  Confirmado: { label: "Pasar a preparación", value: ORDER_STATUS_VALUES.Preparando },
  Preparando: { label: "Marcar listo", value: ORDER_STATUS_VALUES.Listo },
  Listo: { label: "Enviar a reparto", value: ORDER_STATUS_VALUES.EnCamino },
  EnCamino: { label: "Marcar entregado", value: ORDER_STATUS_VALUES.Entregado },
}

export const TERMINAL_STATUSES = new Set(["Entregado", "Cancelado"])

export function isTerminal(status: string): boolean {
  return TERMINAL_STATUSES.has(status)
}

export function getNextTransition(status: string): Transition | undefined {
  return NEXT_TRANSITIONS[status]
}