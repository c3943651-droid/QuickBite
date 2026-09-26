import { useMemo, useState } from "react"
import { Eye, Search } from "lucide-react"
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
import { UserDetailDialog } from "@/components/features/users/user-detail-dialog"
import {
  USER_ROLE_LIST,
  userRoleLabel,
  useAdminUsers,
  type AdminUserListItem,
  type UserRoleValue,
} from "@/lib/api/admin/users"
import { useDebouncedValue } from "@/hooks/use-debounced-value"
import { formatDateTime } from "@/lib/format"

function initials(nombre: string): string {
  return nombre
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0])
    .join("")
    .toUpperCase()
}

const ACTIVE_FILTER_OPTIONS = [
  { value: "activo", label: "Solo activos" },
  { value: "inactivo", label: "Solo inactivos" },
] as const

type ActiveFilterValue = (typeof ACTIVE_FILTER_OPTIONS)[number]["value"]

const ROLE_CHIP_STYLES: Record<string, string> = {
  administrador: "bg-blue-100 text-blue-800 dark:bg-blue-500/15 dark:text-blue-300",
  repartidor: "bg-violet-100 text-violet-800 dark:bg-violet-500/15 dark:text-violet-300",
  cliente: "bg-muted text-muted-foreground",
}

export default function UsersPage() {
  const [search, setSearch] = useState("")
  const debouncedSearch = useDebouncedValue(search, 300)
  const [rol, setRol] = useState<"" | UserRoleValue>("")
  const [estado, setEstado] = useState<"" | ActiveFilterValue>("")
  const [sortKey, setSortKey] = useState("")
  const [sortDir, setSortDir] = useState<"asc" | "desc">("asc")
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(10)
  const [detailUserId, setDetailUserId] = useState<string | null>(null)

  const { data, isLoading, isFetching, isError, refetch } = useAdminUsers({
    params: {
      search: debouncedSearch.trim() || undefined,
      rol: rol || undefined,
      activo: estado === "" ? undefined : estado === "activo",
      page,
      limit,
    },
  })

  const sorted = useMemo(() => {
    const items = data?.data ?? []
    if (!sortKey) return items
    const dir = sortDir === "asc" ? 1 : -1
    return [...items].sort((a, b) => {
      const av = a[sortKey as keyof AdminUserListItem]
      const bv = b[sortKey as keyof AdminUserListItem]
      if (typeof av === "boolean" && typeof bv === "boolean") return (Number(av) - Number(bv)) * dir
      if (typeof av === "number" && typeof bv === "number") return (av - bv) * dir
      return String(av ?? "").localeCompare(String(bv ?? "")) * dir
    })
  }, [data, sortKey, sortDir])

  const total = data?.total ?? 0
  const totalPages = Math.max(1, Math.ceil(total / limit))
  const currentPage = Math.min(page, totalPages)

  const columns: DataColumn<AdminUserListItem>[] = [
    {
      key: "nombre",
      header: "Usuario",
      sortable: true,
      render: (item) => (
        <div className="flex min-w-0 items-center gap-3">
          <div className="bg-primary/10 text-primary flex size-9 shrink-0 items-center justify-center rounded-full text-xs font-semibold">
            {initials(item.nombre)}
          </div>
          <div className="min-w-0">
            <p className="truncate font-medium">{item.nombre}</p>
            <p className="text-muted-foreground truncate text-xs">{item.email}</p>
          </div>
        </div>
      ),
    },
    {
      key: "rol",
      header: "Rol",
      sortable: true,
      render: (item) => (
        <span
          className={`inline-flex rounded-full px-2 py-0.5 text-xs font-medium ${ROLE_CHIP_STYLES[item.rol] ?? "bg-muted text-muted-foreground"}`}
        >
          {userRoleLabel(item.rol)}
        </span>
      ),
    },
    {
      key: "activo",
      header: "Estado",
      sortable: true,
      render: (item) => <StatusChip status={item.activo ? "Activo" : "Inactivo"} />,
    },
    {
      key: "ultimoLogin",
      header: "Último acceso",
      sortable: true,
      render: (item) =>
        item.ultimoLogin ? (
          formatDateTime(item.ultimoLogin)
        ) : (
          <span className="text-muted-foreground">Nunca</span>
        ),
    },
    {
      key: "acciones",
      header: "",
      className: "text-right",
      render: (item) => (
        <div
          className="flex justify-end gap-1"
          onClick={(event) => event.stopPropagation()}
        >
          <Button
            variant="ghost"
            size="sm"
            aria-label="Ver detalle"
            onClick={() => setDetailUserId(item.id)}
          >
            <Eye className="size-4" />
          </Button>
        </div>
      ),
    },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Usuarios</h1>
        <p className="text-muted-foreground text-sm">
          Gestiona perfiles, roles y estado de las cuentas.
        </p>
      </div>

      <div className="flex flex-wrap items-center gap-2">
        <div className="relative min-w-52 flex-1 sm:max-w-xs">
          <Search className="text-muted-foreground pointer-events-none absolute top-1/2 left-2.5 size-4 -translate-y-1/2" />
          <Input
            placeholder="Buscar por nombre, email o teléfono…"
            value={search}
            onChange={(event) => {
              setSearch(event.target.value)
              setPage(1)
            }}
            className="pl-8"
          />
        </div>
        <Select
          value={rol}
          onValueChange={(value) => {
            setRol(value as "" | UserRoleValue)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-44">
            <SelectValue placeholder="Todos los roles" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Todos los roles</SelectItem>
            {USER_ROLE_LIST.map((role) => (
              <SelectItem key={role.value} value={role.value}>
                {role.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select
          value={estado}
          onValueChange={(value) => {
            setEstado(value as "" | ActiveFilterValue)
            setPage(1)
          }}
        >
          <SelectTrigger className="w-44">
            <SelectValue placeholder="Todos los estados" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="">Todos los estados</SelectItem>
            {ACTIVE_FILTER_OPTIONS.map((option) => (
              <SelectItem key={option.value} value={option.value}>
                {option.label}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {isError ? (
        <ErrorState
          title="No se pudieron cargar los usuarios"
          description="Revisa tu conexión o intenta nuevamente."
          onRetry={() => void refetch()}
        />
      ) : (
        <DataTable
          columns={columns}
          data={sorted}
          rowKey={(item) => item.id}
          loading={isLoading || isFetching}
          currentPage={currentPage}
          pageSize={limit}
          totalItems={total}
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
          emptyTitle="Sin usuarios"
          emptyDescription="Ajusta los filtros o intenta otra búsqueda."
        />
      )}

      <UserDetailDialog
        userId={detailUserId}
        onOpenChange={(open) => !open && setDetailUserId(null)}
      />
    </div>
  )
}