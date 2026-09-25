import { useQuery } from "@tanstack/react-query"
import { getApiV1AdminAudit } from "@/lib/api/generated/admin-audit/admin-audit"
import { queryKeys } from "@/lib/api/query-keys"

export interface AuditUser {
  id: string
  nombre: string
  email: string
}

export interface AuditEntry {
  id: string
  usuarioId: string | null
  usuario: AuditUser | null
  accion: string
  entidad: string
  entidadId: string | null
  detalles: string | null
  ipOrigen: string | null
  userAgent: string | null
  creadoEn: string
}

export function useAuditLog() {
  return useQuery({
    queryKey: queryKeys.audit.all,
    queryFn: () => getApiV1AdminAudit() as unknown as Promise<AuditEntry[]>,
  })
}