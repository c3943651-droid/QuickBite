import { useMemo, useState } from "react"
import { cn } from "cn"
import { PackageOpen, Search } from "lucide-react"
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
import { StockAdjustDialog } from "@/components/features/inventory/stock-adjust-dialog"
import { useAdminCategories } from "@/lib/api/admin/categories"
import { useAdminProducts, type ProductListItem } from "@/lib/api/admin/products"
import { useDebouncedValue } from "@/hooks/use-debounced-value"

type StockLevel = "ok" | "bajo" | "agotado" | "nulo"

function stockLevel(product: ProductListItem): StockLevel {
  if (product.stock === null) return "nulo"
  if (product.stock === 0) return "agotado"
  if (product.stockMinimo !== null && product.stock <= product.stockMinimo) return "bajo"
  return "ok"
}

function StockLevelChip({ product }: { product: ProductListItem }) {
  const level = stockLevel(product)
  const styles: Record<StockLevel, { label: string; className: string }> = {
    ok: { label: "En nivel", className: "bg-emerald-100 text-emerald-800 dark:bg-emerald-500/15 dark:text-emerald-300" },
    bajo: { label: "Stock bajo", className: "bg-amber-100 text-amber-800 dark:bg-amber-500/15 dark:text-amber-300" },
    agotado: { label: "Agotado", className: "bg-red-100 text-red-800 dark:bg-red-500/15 dark:text-red-300" },
    nulo: { label: "Sin control", className: "bg-muted text-muted-foreground" },
  }
  const style = styles[level]
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-xs font-medium whitespace-nowrap",
        style.className,
      )}
    >
      <span className="size-1.5 rounded-full bg-current opacity-70" aria-hidden="true" />
      {style.label}
    </span>
  )
}

export default function InventoryPage() {
  const [search, setSearch] = useState("")
  const debouncedSearch = useDebouncedValue(search, 300)
  const [categoriaId, setCategoriaId] = useState("")
  const [nivel, setNivel] = useState("")
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(50)
  const [adjusting, setAdjusting] = useState<ProductListItem | null>(null)

  const { data: categorias = [] } = useAdminCategories()

  const params = useMemo(
    () => ({
      page,
      limit,
      categoriaId: categoriaId || undefined,
      search: debouncedSearch || undefined,
    }),
    [page, limit, categoriaId, debouncedSearch],
  )

  const { data, isLoading, isFetching, isError, refetch } = useAdminProducts(params)

  const visibleData = useMemo(() => {
    const rows = data?.data ?? []
    if (nivel === "") return rows
    return rows.filter((product) => {
      const level = stockLevel(product)
      if (nivel === "bajo") return level === "bajo" || level === "agotado"
      if (nivel === "agotado") return level === "agotado"
      return true
    })
  }, [data, nivel])

  const columns: DataColumn<ProductListItem>[] = [
    {
      key: "nombre",
      header: "Producto",
      render: (product) => (
        <div className="flex min-w-0 items-center gap-3">
          {product.imagenUrl ? (
            <img
              src={product.imagenUrl}
              alt=""
              className="size-9 shrink-0 rounded-md border border-border object-cover"
            />
          ) : (
            <div className="flex size-9 shrink-0 items-center justify-center rounded-md border border-dashed text-muted-foreground" aria-hidden="true">
              <PackageOpen className="size-4" />
            </div>
          )}
          <div className="min-w-0">
            <p className="truncate font-medium">{product.nombre}</p>
            {product.categoria ? (
              <p className="truncate text-muted-foreground text-xs">{product.categoria.nombre}</p>
            ) : null}
          </div>
        </div>
      ),
    },
    {
      key: "stock",
      header: "Stock",
      className: "tabular-nums",
      render: (product) =>
        product.stock === null ? "—" : String(product.stock),
    },
    {
      key: "stockMinimo",
      header: "Stock mínimo",
      className: "tabular-nums",
      render: (product) =>
        product.stockMinimo === null ? "—" : String(product.stockMinimo),
    },
    {
      key: "nivel",
      header: "Nivel",
      render: (product) => <StockLevelChip product={product} />,
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
        <div className="flex justify-end gap-1" onClick={(event) => event.stopPropagation()}>
          <Button
            variant="outline"
            size="sm"
            disabled={product.stock === null}
            onClick={() => setAdjusting(product)}
          >
            Ajustar stock
          </Button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-semibold">Inventario</h1>
          <p className="text-muted-foreground text-sm">
            Controla los niveles de stock de cada producto.
          </p>
        </div>
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
          value={nivel}
          onValueChange={(value) => {
            setNivel(value)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-40">
            <SelectValue placeholder="Todos los niveles" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Todos los niveles</SelectItem>
            <SelectItem value="bajo">Stock bajo</SelectItem>
            <SelectItem value="agotado">Agotados</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {isError ? (
        <ErrorState
          title="No se pudo cargar el inventario"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : (
        <DataTable
          columns={columns}
          data={visibleData}
          rowKey={(product) => product.id}
          loading={isLoading || isFetching}
          currentPage={page}
          pageSize={limit}
          totalItems={nivel === "" ? (data?.total ?? 0) : visibleData.length}
          onPageChange={setPage}
          onPageSizeChange={(size) => {
            setLimit(size)
            setPage(1)
          }}
          emptyTitle="Sin productos"
          emptyDescription="Ajusta los filtros o crea productos con stock."
        />
      )}

      <StockAdjustDialog
        open={adjusting !== null}
        onOpenChange={(open) => !open && setAdjusting(null)}
        product={adjusting}
      />
    </div>
  )
}