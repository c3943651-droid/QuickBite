import { useMutation, useQueryClient } from "@tanstack/react-query"
import { patchApiV1AdminProductsIdStock } from "@/lib/api/generated/admin-catalog/admin-catalog"
import { queryKeys } from "@/lib/api/query-keys"
import type { ProductDetail } from "@/lib/api/admin/products"

export function useAdjustStock() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, stock, motivo }: { id: string; stock: number; motivo: string }) =>
      patchApiV1AdminProductsIdStock(id, { stock, motivo }) as unknown as Promise<ProductDetail>,
    onSuccess: (_result, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.products.all })
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.detail(variables.id),
      })
    },
  })
}