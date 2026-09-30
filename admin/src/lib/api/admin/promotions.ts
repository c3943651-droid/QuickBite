import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import { customInstance } from "@/lib/api/custom-instance"
import { queryKeys } from "@/lib/api/query-keys"

export interface PromotionResponse {
  id: string
  titulo: string
  subtitulo: string
  colorHex: string
}

export interface CreatePromotionRequest {
  titulo: string
  subtitulo: string
  colorHex: string
  orden: number
}

export interface UpdatePromotionRequest {
  titulo?: string
  subtitulo?: string
  colorHex?: string
  orden?: number
  activa?: boolean
}

export function useAdminPromotions(options?: { enabled?: boolean }) {
  return useQuery({
    queryKey: queryKeys.promotions.all,
    queryFn: () =>
      customInstance<PromotionResponse[]>({
        method: "GET",
        url: "/api/v1/admin/promotions",
      }),
    enabled: options?.enabled,
  })
}

export function useCreatePromotion() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ data }: { data: CreatePromotionRequest }) =>
      customInstance<PromotionResponse>({
        method: "POST",
        url: "/api/v1/admin/promotions",
        data,
      }),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.promotions.all })
    },
  })
}

export function useUpdatePromotion() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdatePromotionRequest }) =>
      customInstance<PromotionResponse>({
        method: "PUT",
        url: `/api/v1/admin/promotions/${id}`,
        data,
      }),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.promotions.all })
    },
  })
}

export function useDeletePromotion() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id }: { id: string }) =>
      customInstance<void>({
        method: "DELETE",
        url: `/api/v1/admin/promotions/${id}`,
      }),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.promotions.all })
    },
  })
}
