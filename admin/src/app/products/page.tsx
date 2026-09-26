import { useMemo, useState } from "react"
import { toast } from "sonner"
import { cn } from "cn"
import { LayoutGrid, List, Plus, Search } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { DataTable, type DataColumn } from "@/components/common/data-table"
import { ErrorState } from "@/components/common/error-state"
import { StatusChip } from "@/components/common/status-chip"
import { ConfirmDialog } from "@/components/common/confirm-dialog"
import { ProductFormDialog } from "@/components/features/products/product-form-dialog"
import { ProductPriceHistoryDialog } from "@/components/features/products/product-price-history-dialog"
import { ImageLightbox } from "@/components/features/products/image-lightbox"
import {
  ProductActionsMenu,
  ProductGrid,
  ProductGridSkeleton,
} from "@/components/features/products/product-grid"
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
  const [view, setView] = useState<"grid" | "list">("grid")
  const [pendingId, setPendingId] = useState<string | null>(null)
  const [historyProduct, setHistoryProduct] = useState<ProductListItem | null>(null)
  const [previewProduct, setPreviewProduct] = useState<ProductListItem | null>(null)
  const [deletingProduct, setDeletingProduct] = useState<ProductListItem | null>(null)
  const [availabilityTarget, setAvailabilityTarget] = useState<ProductListItem | null>(null)

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
  const totalPages = Math.max(1, Math.ceil((data?.total ?? 0) / limit))

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

  async function confirmToggleAvailability() {
    if (!availabilityTarget) return
    const target = availabilityTarget
    setPendingId(target.id)
    try {
      await setAvailability.mutateAsync({
        id: target.id,
        data: { disponible: !target.disponible },
      })
      toast.success(
        target.disponible
          ? "Producto desactivado correctamente"
          : "Producto activado correctamente",
      )
      setAvailabilityTarget(null)
    } catch (error) {
      toast.error(getApiErrorMessage(error, "No se pudo cambiar el estado. Inténtalo de nuevo."))
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
          <ProductActionsMenu
            product={product}
            onEdit={openEdit}
            onToggle={setAvailabilityTarget}
            onHistory={setHistoryProduct}
            onDelete={setDeletingProduct}
            disabled={pendingId === product.id}
          />
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
        <div className="flex items-center gap-0.5 rounded-lg bg-zinc-100 p-0.5">
          <Button
            variant={view === "grid" ? "default" : "ghost"}
            size="icon-sm"
            aria-label="Vista de cuadrícula"
            aria-pressed={view === "grid"}
            className={cn("rounded-[6px]", view !== "grid" && "text-zinc-500")}
            onClick={() => setView("grid")}
          >
            <LayoutGrid className="size-4" />
          </Button>
          <Button
            variant={view === "list" ? "default" : "ghost"}
            size="icon-sm"
            aria-label="Vista de lista"
            aria-pressed={view === "list"}
            className={cn("rounded-[6px]", view !== "list" && "text-zinc-500")}
            onClick={() => setView("list")}
          >
            <List className="size-4" />
          </Button>
        </div>
      </div>

      {isError ? (
        <ErrorState
          title="No se pudieron cargar los productos"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : view === "grid" ? (
        <>
          {isLoading || isFetching ? (
            <ProductGridSkeleton />
          ) : (data?.data ?? []).length > 0 ? (
            <ProductGrid
              products={data?.data ?? []}
              onEdit={openEdit}
              onToggle={setAvailabilityTarget}
              onHistory={setHistoryProduct}
              onDelete={setDeletingProduct}
              onPreview={setPreviewProduct}
              pendingId={pendingId}
            />
          ) : (
            <div className="rounded-xl border border-dashed border-zinc-200 bg-zinc-50/50 p-8 text-center">
              <p className="text-sm font-medium text-zinc-600">Sin productos</p>
              <p className="mt-1 text-sm text-zinc-500">
                Ajusta los filtros o crea un nuevo producto.
              </p>
            </div>
          )}
          {(data?.data ?? []).length > 0 ? (
            <div className="flex items-center justify-between gap-2 pt-4">
              <Button
                variant="outline"
                size="sm"
                className="h-8"
                disabled={page <= 1}
                onClick={() => setPage(page - 1)}
              >
                Anterior
              </Button>
              <span className="text-sm text-muted-foreground">
                Página {Math.min(page, totalPages)} de {totalPages}
              </span>
              <Button
                variant="outline"
                size="sm"
                className="h-8"
                disabled={page >= totalPages}
                onClick={() => setPage(page + 1)}
              >
                Siguiente
              </Button>
            </div>
          ) : null}
        </>
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

      <ProductPriceHistoryDialog
        open={historyProduct !== null}
        onOpenChange={(open) => {
          if (!open) setHistoryProduct(null)
        }}
        product={historyProduct}
      />

      {previewProduct ? (
        <ImageLightbox product={previewProduct} onClose={() => setPreviewProduct(null)} />
      ) : null}

      <ConfirmDialog
        open={availabilityTarget !== null}
        onOpenChange={(open) => {
          if (!open) setAvailabilityTarget(null)
        }}
        title={
          availabilityTarget
            ? `¿${availabilityTarget.disponible ? "Desactivar" : "Activar"} "${availabilityTarget.nombre}"?`
            : ""
        }
        description={
          availabilityTarget
            ? availabilityTarget.disponible
              ? "Este producto dejará de estar visible para los clientes en el menú digital de forma inmediata."
              : "El producto volverá a estar disponible para los clientes en el menú digital."
            : undefined
        }
        confirmLabel={availabilityTarget?.disponible ? "Desactivar" : "Activar"}
        tone={availabilityTarget?.disponible ? "amber" : "default"}
        loading={setAvailability.isPending}
        onConfirm={() => void confirmToggleAvailability()}
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