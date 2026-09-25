import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query"
import type {
  CreateProductOptionRequest,
  CreateProductRequest,
  GetApiV1ProductsParams,
  PostApiV1AdminProductsUploadImageBody,
  SetAvailabilityRequest,
  UpdateProductOptionRequest,
  UpdateProductRequest,
} from "@/lib/api/generated/quickBiteAPI.schemas"
import {
  deleteApiV1AdminProductsId,
  deleteApiV1AdminProductsIdOptionsOptionId,
  getApiV1AdminProductsIdPriceHistory,
  patchApiV1AdminProductsIdAvailability,
  postApiV1AdminProducts,
  postApiV1AdminProductsIdOptions,
  postApiV1AdminProductsUploadImage,
  putApiV1AdminProductsId,
  putApiV1AdminProductsIdOptionsOptionId,
} from "@/lib/api/generated/admin-catalog/admin-catalog"
import {
  getApiV1Products,
  getApiV1ProductsId,
  getApiV1ProductsIdOptions,
} from "@/lib/api/generated/catalog/catalog"
import type { CategoryResponse } from "@/lib/api/admin/categories"
import type { PagedResponse } from "@/lib/api/admin/types"
import { queryKeys } from "@/lib/api/query-keys"

export interface ProductListItem {
  id: string
  nombre: string
  descripcion: string | null
  precio: number
  imagenUrl: string | null
  disponible: boolean
  categoria: CategoryResponse | null
  stock: number | null
  stockMinimo: number | null
}

export interface ProductOption {
  id: string
  nombre: string
  precioAdicional: number
  activo: boolean
}

export interface ProductDetail {
  id: string
  nombre: string
  descripcion: string | null
  precio: number
  imagenUrl: string | null
  disponible: boolean
  categoria: CategoryResponse | null
  opciones: ProductOption[]
  stock: number | null
}

export interface ProductPriceHistoryEntry {
  id: string
  precioAnterior: number
  precioNuevo: number
  usuario: string | null
  motivo: string | null
  creadoEn: string
}

export function useAdminProducts(params: GetApiV1ProductsParams) {
  return useQuery({
    queryKey: [...queryKeys.products.all, params] as const,
    queryFn: () => getApiV1Products(params) as unknown as Promise<PagedResponse<ProductListItem>>,
  })
}

export function useAdminProductDetail(
  productId: string | null,
  options?: { enabled?: boolean },
) {
  return useQuery({
    queryKey: productId ? queryKeys.products.detail(productId) : [...queryKeys.products.all],
    queryFn: () => getApiV1ProductsId(productId as string) as unknown as Promise<ProductDetail>,
    enabled: Boolean(productId) && (options?.enabled ?? true),
  })
}

export function useAdminProductOptions(
  productId: string | null,
  options?: { enabled?: boolean },
) {
  return useQuery({
    queryKey: productId ? queryKeys.products.options(productId) : [...queryKeys.products.all],
    queryFn: () => getApiV1ProductsIdOptions(productId as string) as unknown as Promise<ProductOption[]>,
    enabled: Boolean(productId) && (options?.enabled ?? true),
  })
}

export function useAdminProductPriceHistory(productId: string | null) {
  return useQuery({
    queryKey: productId ? queryKeys.products.priceHistory(productId) : [...queryKeys.products.all],
    queryFn: () =>
      getApiV1AdminProductsIdPriceHistory(productId as string) as unknown as Promise<ProductPriceHistoryEntry[]>,
    enabled: Boolean(productId),
  })
}

export function useCreateProduct() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ data }: { data: CreateProductRequest }) =>
      postApiV1AdminProducts(data) as unknown as Promise<ProductDetail>,
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.products.all })
    },
  })
}

export function useUpdateProduct() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: UpdateProductRequest }) =>
      putApiV1AdminProductsId(id, data) as unknown as Promise<ProductDetail>,
    onSuccess: (_result, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.products.all })
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.detail(variables.id),
      })
    },
  })
}

export function useDeleteProduct() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id }: { id: string }) => deleteApiV1AdminProductsId(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.products.all })
    },
  })
}

export function useSetAvailability() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: SetAvailabilityRequest }) =>
      patchApiV1AdminProductsIdAvailability(id, data) as unknown as Promise<ProductDetail>,
    onSuccess: (_result, variables) => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.products.all })
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.detail(variables.id),
      })
    },
  })
}

export function useUploadProductImage() {
  return useMutation({
    mutationFn: ({ file }: PostApiV1AdminProductsUploadImageBody) =>
      postApiV1AdminProductsUploadImage({ file }) as unknown as Promise<{
        imageUrl: string
      }>,
  })
}

export function useCreateProductOption() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, data }: { id: string; data: CreateProductOptionRequest }) =>
      postApiV1AdminProductsIdOptions(id, data) as unknown as Promise<ProductOption>,
    onSuccess: (_result, variables) => {
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.detail(variables.id),
      })
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.options(variables.id),
      })
    },
  })
}

export function useUpdateProductOption() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({
      id,
      optionId,
      data,
    }: {
      id: string
      optionId: string
      data: UpdateProductOptionRequest
    }) => putApiV1AdminProductsIdOptionsOptionId(id, optionId, data) as unknown as Promise<ProductOption>,
    onSuccess: (_result, variables) => {
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.detail(variables.id),
      })
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.options(variables.id),
      })
    },
  })
}

export function useDeleteProductOption() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: ({ id, optionId }: { id: string; optionId: string }) =>
      deleteApiV1AdminProductsIdOptionsOptionId(id, optionId),
    onSuccess: (_result, variables) => {
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.detail(variables.id),
      })
      void queryClient.invalidateQueries({
        queryKey: queryKeys.products.options(variables.id),
      })
    },
  })
}