import type { ReactNode } from "react"
import { cn } from "cn"
import {
  ArrowDown,
  ArrowUp,
  ArrowUpDown,
  ChevronLeft,
  ChevronRight,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { EmptyState } from "@/components/common/empty-state"
import { Skeleton } from "@/components/ui/skeleton"

export interface DataColumn<T> {
  key: string
  header: string
  sortable?: boolean
  className?: string
  render: (row: T) => ReactNode
}

export interface DataTableProps<T> {
  columns: DataColumn<T>[]
  data: T[]
  rowKey: (row: T) => string
  loading?: boolean
  currentPage?: number
  pageSize?: number
  totalItems?: number
  onPageChange?: (page: number) => void
  onPageSizeChange?: (size: number) => void
  sortKey?: string
  sortDir?: "asc" | "desc"
  onSortChange?: (key: string, dir: "asc" | "desc") => void
  emptyTitle?: string
  emptyDescription?: string
  empty?: ReactNode
  onRowClick?: (row: T) => void
  className?: string
}

function SortHeader<T>({ column, sortKey, sortDir, onSortChange }: {
  column: DataColumn<T>
  sortKey?: string
  sortDir?: "asc" | "desc"
  onSortChange?: (key: string, dir: "asc" | "desc") => void
}) {
  if (!column.sortable || !onSortChange) {
    return <span>{column.header}</span>
  }

  const active = sortKey === column.key
  const Icon = !active ? ArrowUpDown : sortDir === "asc" ? ArrowUp : ArrowDown

  return (
    <button
      type="button"
      className="inline-flex items-center gap-1 hover:text-foreground"
      onClick={() => {
        const nextDir =
          !active ? "asc" : sortDir === "asc" ? "desc" : "asc"
        onSortChange(column.key, nextDir)
      }}
    >
      {column.header}
      <Icon className={cn("size-3.5", active ? "opacity-100" : "opacity-40")} />
    </button>
  )
}

export function DataTable<T>({
  columns,
  data,
  rowKey,
  loading = false,
  currentPage = 1,
  pageSize = 10,
  totalItems = 0,
  onPageChange,
  onPageSizeChange,
  sortKey,
  sortDir,
  onSortChange,
  emptyTitle,
  emptyDescription,
  empty,
  onRowClick,
  className,
}: DataTableProps<T>) {
  const totalPages = Math.max(1, Math.ceil(totalItems / Math.max(1, pageSize)))
  const from = totalItems === 0 ? 0 : (currentPage - 1) * pageSize + 1
  const to = Math.min(currentPage * pageSize, totalItems)

  return (
    <div className={cn("space-y-3", className)}>
      <Table>
        <TableHeader>
          <TableRow>
            {columns.map((column) => (
              <TableHead key={column.key} className={column.className}>
                <SortHeader
                  column={column}
                  sortKey={sortKey}
                  sortDir={sortDir}
                  onSortChange={onSortChange}
                />
              </TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {loading ? (
            Array.from({ length: Math.min(pageSize, 5) }).map((_, index) => (
              <TableRow key={`skeleton-${index}`}>
                {columns.map((column) => (
                  <TableCell key={column.key} className={column.className}>
                    <Skeleton className="h-4 w-full" />
                  </TableCell>
                ))}
              </TableRow>
            ))
          ) : data.length === 0 ? (
            <TableRow>
              <TableCell colSpan={columns.length}>
                {empty ?? (
                  <EmptyState title={emptyTitle} description={emptyDescription} />
                )}
              </TableCell>
            </TableRow>
          ) : (
            data.map((row) => (
              <TableRow
                key={rowKey(row)}
                onClick={onRowClick ? () => onRowClick(row) : undefined}
                className={cn(onRowClick && "cursor-pointer")}
              >
                {columns.map((column) => (
                  <TableCell key={column.key} className={column.className}>
                    {column.render(row)}
                  </TableCell>
                ))}
              </TableRow>
            ))
          )}
        </TableBody>
      </Table>

      <div className="flex flex-col items-center justify-between gap-2 sm:flex-row">
        <p className="text-sm text-muted-foreground">
          {from}–{to} de {totalItems} registros
        </p>
        <div className="flex items-center gap-2">
          {onPageSizeChange ? (
            <Select
              value={String(pageSize)}
              onValueChange={(value) => onPageSizeChange(Number(value))}
            >
              <SelectTrigger className="h-8 w-24">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                {[10, 25, 50].map((size) => (
                  <SelectItem key={size} value={String(size)}>
                    {size} / página
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          ) : null}
          <Button
            variant="outline"
            size="sm"
            disabled={currentPage <= 1 || totalItems === 0}
            onClick={() => onPageChange?.(currentPage - 1)}
          >
            <ChevronLeft className="size-4" />
            Anterior
          </Button>
          <span className="text-sm text-muted-foreground">
            {currentPage} / {totalPages}
          </span>
          <Button
            variant="outline"
            size="sm"
            disabled={currentPage >= totalPages || totalItems === 0}
            onClick={() => onPageChange?.(currentPage + 1)}
          >
            Siguiente
            <ChevronRight className="size-4" />
          </Button>
        </div>
      </div>
    </div>
  )
}