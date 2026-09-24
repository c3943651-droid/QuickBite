import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import type {
  CreateCategoryRequest,
  UpdateCategoryRequest,
} from "@/lib/api/generated/quickBiteAPI.schemas"
import {
  deleteApiV1AdminCategoriesId,
  getApiV1AdminCategories,
  postApiV1AdminCategories,
  putApiV1AdminCategoriesId,
} from "@/lib/api/generated/admin-catalog/admin-catalog"
import { queryKeys } from "@/lib/api/query-keys"

export interface CategoryResponse {
  id: string
  nombre: string
  descripcion: string | null
  orden: number
  activo: boolean
}

export function useAdminCategories(options?: { enabled?: boolean }) {
  return useQuery({
    queryKey: queryKeys.categories.all,
    queryFn: () => getApiV1AdminCategories() as unknown as Promise<CategoryResponse[]>,
    enabled: options?.enabled,
  })
}

export function useCreateCategory() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ data }: { data: CreateCategoryRequest }) =>
      postApiV1AdminCategories(data) as unknown as Promise<CategoryResponse>,
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.categories.all })
    },
  })
}

export function useUpdateCategory() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateCategoryRequest }) =>
      putApiV1AdminCategoriesId(id, data) as unknown as Promise<CategoryResponse>,
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.categories.all })
    },
  })
}

export function useDeleteCategory() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id }: { id: string }) => deleteApiV1AdminCategoriesId(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.categories.all })
    },
  })
}