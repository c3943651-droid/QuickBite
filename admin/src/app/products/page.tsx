import { useMemo, useState } from "react"
import { toast } from "sonner"
import { cn } from "cn"
import { Boxes, History, MoreHorizontal, Pencil, Plus, Power, Search, Trash2 } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { ErrorState } from "@/components/common/error-state"
import { StatusChip } from "@/components/common/status-chip"
import { ConfirmDialog } from "@/components/common/confirm-dialog"
import { ProductFormDialog } from "@/components/features/products/product-form-dialog"
import { ProductPriceHistoryDialog } from "@/components/features/products/product-price-history-dialog"
import { StockAdjustDialog } from "@/components/features/inventory/stock-adjust-dialog"
import { useAdminCategories } from "@/lib/api/admin/categories"
import {
  useAdminProducts,
  useDeleteProduct,
  useSetAvailability,
  type ProductListItem,
} from "@/lib/api/admin/products"
import { getApiErrorMessage } from "@/lib/api/error"
import { formatCurrency } from "@/lib/format"
import { useDebouncedValue } from "@/hooks/use-debounced-value"
import type {
  GetApiV1ProductsParams,
} from "@/lib/api/generated/quickBiteAPI.schemas"

export default function ProductsPage() {
  const [search, setSearch] = useState("")
  const debouncedSearch = useDebouncedValue(search, 300)
  const [categoriaId, setCategoriaId] = useState("")
  const [estado, setEstado] = useState("")
  const [sortKey, setSortKey] = useState("")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc")
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(25)
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editingProduct, setEditingProduct] = useState<ProductListItem | null>(null)
  const [pendingId, setPendingId] = useState<string | null>(null)
  const [adjustProduct, setAdjustProduct] = useState<ProductListItem | null>(null)
  const [historyProduct, setHistoryProduct] = useState<ProductListItem | null>(null)
  const [deletingProduct, setDeletingProduct] = useState<ProductListItem | null>(null)

  const { data: categorias = [] } = useAdminCategories()
  const setAvailability = useSetAvailability()
  const deleteProduct = useDeleteProduct()

  const params = useMemo<GetApiV1ProductsParams>(() => {
    const disponible = estado === "" ? undefined : estado === "true"
    return {
      page,
      limit,
      categoriaId: categoriaId || undefined,
      search: debouncedSearch || undefined,
      disponible,
      orden: sortKey ? `${sortKey}_${sortDir}` : undefined,
    }
  }, [page, limit, categoriaId, debouncedSearch, estado, sortKey, sortDir])

  const { data, isLoading, isFetching, isError, refetch } = useAdminProducts(params)

  function openCreate() {
    setEditingProduct(null)
    setDialogOpen(true)
  }

  function openEdit(product: ProductListItem) {
    setEditingProduct(product)
    setDialogOpen(true)
  }

  async function handleDelete() {
    if (!deletingProduct) return
    try {
      await deleteProduct.mutateAsync({ id: deletingProduct.id })
      toast.success(`Producto "${deletingProduct.nombre}" eliminado`)
      setDeletingProduct(null)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo eliminar el producto"))
    }
  }

  async function toggleAvailability(product: ProductListItem) {
    setPendingId(product.id)
    try {
      await setAvailability.mutateAsync({
        id: product.id,
        data: { disponible: !product.disponible },
      })
      toast.success(product.disponible ? "Producto desactivado" : "Producto activado")
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo cambiar la disponibilidad"))
    } finally {
      setPendingId(null)
    }
  }

  const columns: DataColumn<ProductListItem>[] = [
    {
      key: "nombre",
      header: "Producto",
      sortable: true,
      render: (product) => (
        <div className="flex min-w-0 items-center gap-3">
          {product.imagenUrl ? (
            <img
              src={product.imagenUrl}
              alt=""
              className="size-10 shrink-0 rounded-md border border-border object-cover"
            />
          ) : (
            <div className="flex size-10 shrink-0 items-center justify-center rounded-md border border-dashed text-muted-foreground text-[10px]">
              Sin img
            </div>
          )}
          <div className="min-w-0">
            <p className="truncate font-medium">{product.nombre}</p>
            {product.categoria ? (
              <p className="truncate text-muted-foreground text-xs">
                {product.categoria.nombre}
              </p>
            ) : (
              <p className="text-muted-foreground text-xs">Sin categoría</p>
            )}
          </div>
        </div>
      ),
    },
    {
      key: "precio",
      header: "Precio",
      sortable: true,
      className: "tabular-nums",
      render: (product) => formatCurrency(product.precio),
    },
    {
      key: "stock",
      header: "Stock",
      className: "tabular-nums",
      render: (product) => {
        if (product.stock === null) {
          return <span className="text-muted-foreground">—</span>
        }
        const low =
          product.stockMinimo !== null && product.stock <= product.stockMinimo
        return (
          <span className={cn(low && "font-medium text-amber-600 dark:text-amber-400")}>
            {product.stock}
            {product.stockMinimo !== null ? (
              <span className="text-muted-foreground"> / mín. {product.stockMinimo}</span>
            ) : null}
          </span>
        )
      },
    },
    {
      key: "estado",
      header: "Estado",
      render: (product) =>
        product.disponible ? (
          <StatusChip status="Disponible" />
        ) : (
          <StatusChip status="No disponible" />
        ),
    },
    {
      key: "acciones",
      header: "",
      className: "text-right",
      render: (product) => (
        <div
          className="flex justify-end gap-1"
          onClick={(event) => event.stopPropagation()}
        >
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button variant="ghost" size="icon" aria-label="Acciones">
                <MoreHorizontal className="size-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end">
              <DropdownMenuItem onClick={() => openEdit(product)}>
                <Pencil className="size-4" />
                Editar
              </DropdownMenuItem>
              <DropdownMenuItem
                disabled={pendingId === product.id}
                onClick={() => void toggleAvailability(product)}
              >
                <Power className={cn("size-4", !product.disponible && "text-muted-foreground")} />
                {product.disponible ? "Desactivar" : "Activar"}
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setAdjustProduct(product)}>
                <Boxes className="size-4" />
                Ajustar stock
              </DropdownMenuItem>
              <DropdownMenuItem onClick={() => setHistoryProduct(product)}>
                <History className="size-4" />
                Historial de precios
              </DropdownMenuItem>
              <DropdownMenuSeparator />
              <DropdownMenuItem
                variant="destructive"
                onClick={() => setDeletingProduct(product)}
              >
                <Trash2 className="size-4" />
                Eliminar
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Productos</h1>
          <p className="text-muted-foreground text-sm">
            Administra el catálogo, disponibilidad y opciones.
          </p>
        </div>
        <Button onClick={openCreate}>
          <Plus className="size-4" />
          Nuevo producto
        </Button>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <div className="relative min-w-52 flex-1 sm:max-w-xs">
          <Search className="text-muted-foreground pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2" />
          <Input
            placeholder="Buscar por nombre…"
            value={search}
            onChange={(event) => setSearch(event.target.value)}
            className="pl-8"
          />
        </div>
        <Select
          value={categoriaId}
          onValueChange={(value) => {
            setCategoriaId(value)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-44">
            <SelectValue placeholder="Todas las categorías" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Todas las categorías</SelectItem>
            {categorias.map((categoria) => (
              <SelectItem key={categoria.id} value={categoria.id}>
                {categoria.nombre}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select
          value={estado}
          onValueChange={(value) => {
            setEstado(value)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-40">
            <SelectValue placeholder="Todos los estados" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Todos los estados</SelectItem>
            <SelectItem value="true">Disponibles</SelectItem>
            <SelectItem value="false">No disponibles</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {isError ? (
        <ErrorState
          title="No se pudieron cargar los productos"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : (
        <DataTable
          columns={columns}
          data={data?.data ?? []}
          rowKey={(product) => product.id}
          loading={isLoading || isFetching}
          currentPage={page}
          pageSize={limit}
          totalItems={data?.total ?? 0}
          onPageChange={setPage}
          onPageSizeChange={(size) => {
            setLimit(size)
            setPage(1)
          }}
          sortKey={sortKey}
          sortDir={sortDir}
          onSortChange={(key, dir) => {
            setSortKey(key)
            setSortDir(dir)
            setPage(1)
          }}
          emptyTitle="Sin productos"
          emptyDescription="Ajusta los filtros o crea un nuevo producto."
        />
      )}

      <ProductFormDialog
        open={dialogOpen}
        onOpenChange={setDialogOpen}
        productId={editingProduct?.id ?? null}
        stockMinimo={editingProduct?.stockMinimo}
      />

      <StockAdjustDialog
        open={adjustProduct !== null}
        onOpenChange={(open) => {
          if (!open) setAdjustProduct(null)
        }}
        product={adjustProduct}
      />

      <ProductPriceHistoryDialog
        open={historyProduct !== null}
        onOpenChange={(open) => {
          if (!open) setHistoryProduct(null)
        }}
        product={historyProduct}
      />

      <ConfirmDialog
        open={deletingProduct !== null}
        onOpenChange={(open) => {
          if (!open) setDeletingProduct(null)
        }}
        title={`Eliminar "${deletingProduct?.nombre ?? "producto"}"`}
        description="Esta acción elimina el producto del catálogo y no se puede deshacer."
        confirmLabel="Eliminar"
        destructive
        loading={deleteProduct.isPending}
        onConfirm={() => void handleDelete()}
      />
    </div>
  )
}