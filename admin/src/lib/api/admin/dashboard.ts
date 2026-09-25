import { useQuery } from "@tanstack/react-query"
import { getApiV1AdminDashboard } from "@/lib/api/generated/admin-dashboard/admin-dashboard"
import { queryKeys } from "@/lib/api/query-keys"
import { usePollingOptions } from "@/hooks/use-polling"
import type { UseQueryOptions } from "@tanstack/react-query"

export interface SalesChartItem {
  dia: string
  ventas: number
}

export interface RecentOrder {
  id: string
  numeroPedido: string
  cliente: string
  estado: string
  total: number
  fecha: string
}

export interface DashboardData {
  totalPedidos: number
  ventasTotales: number
  pendientes: number
  porEstado: Record<string, number>
  salesChart: SalesChartItem[]
  recentOrders: RecentOrder[]
}

export async function getAdminDashboard(): Promise<DashboardData> {
  return (await getApiV1AdminDashboard()) as unknown as DashboardData
}

export interface UseAdminDashboardOptions {
  enabled?: boolean
  intervalMs?: number
}

export function useAdminDashboard<TData = DashboardData>(
  options: UseAdminDashboardOptions = {},
  queryOptions?: Omit<UseQueryOptions<DashboardData, unknown, TData>, "queryKey" | "queryFn">,
) {
  const polling = usePollingOptions({ enabled: options.enabled, intervalMs: options.intervalMs })

  return useQuery({
    queryKey: queryKeys.dashboard,
    queryFn: getAdminDashboard,
    ...polling,
    ...queryOptions,
  })
}