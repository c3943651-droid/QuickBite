import { useQuery } from "@tanstack/react-query"
import type {
  GetApiV1AdminReportsSalesByDayParams,
  GetApiV1AdminReportsTopClientsParams,
  GetApiV1AdminReportsTopProductsParams,
} from "@/lib/api/generated/quickBiteAPI.schemas"
import {
  getApiV1AdminReportsDeliveryPerformance,
  getApiV1AdminReportsSalesByDay,
  getApiV1AdminReportsTopClients,
  getApiV1AdminReportsTopProducts,
} from "@/lib/api/generated/admin-reports/admin-reports"
import { queryKeys } from "@/lib/api/query-keys"

export interface SalesByDayItem {
  dia: string
  totalPedidos: number
  entregados: number
  cancelados: number
  activos: number
  ingresos: number
  ticketPromedio: number
}

export interface TopProductItem {
  productoId: string
  nombreProducto: string
  unidadesVendidas: number
  ingresosGenerados: number
  numeroPedidos: number
}

export interface TopClientItem {
  clienteId: string
  nombre: string
  email: string
  totalPedidos: number
  gastoTotal: number
  gastoPromedio: number
  ultimoPedido: string | null
}

export interface DeliveryPerformanceItem {
  repartidorId: string
  nombre: string
  entregasCompletadas: number
  pedidosAsignados: number
  minutosPromedioEntrega: number
  cancelaciones: number
}

export function useSalesByDay(fechaDesde?: string, fechaHasta?: string) {
  const params: GetApiV1AdminReportsSalesByDayParams = { fechaDesde, fechaHasta }
  return useQuery({
    queryKey: [...queryKeys.reports.salesByDay, params],
    queryFn: () =>
      getApiV1AdminReportsSalesByDay(params) as unknown as Promise<SalesByDayItem[]>,
  })
}

export function useTopProducts(limite = 10) {
  const params: GetApiV1AdminReportsTopProductsParams = { limite }
  return useQuery({
    queryKey: [...queryKeys.reports.topProducts, params],
    queryFn: () =>
      getApiV1AdminReportsTopProducts(params) as unknown as Promise<TopProductItem[]>,
  })
}

export function useTopClients(limite = 10) {
  const params: GetApiV1AdminReportsTopClientsParams = { limite }
  return useQuery({
    queryKey: [...queryKeys.reports.topClients, params],
    queryFn: () =>
      getApiV1AdminReportsTopClients(params) as unknown as Promise<TopClientItem[]>,
  })
}

export function useDeliveryPerformance() {
  return useQuery({
    queryKey: queryKeys.reports.deliveryPerformance,
    queryFn: () =>
      getApiV1AdminReportsDeliveryPerformance() as unknown as Promise<DeliveryPerformanceItem[]>,
  })
}