import { useMemo } from "react"
import { useDocumentVisible } from "@/hooks/use-document-visible"

export const DEFAULT_POLLING_MS = 30_000
export const POLLING_MAX_FAILURES = 3

export interface PollingOptions {
  intervalMs?: number
  enabled?: boolean
}

export interface PollingProps {
  refetchInterval: (query: {
    state: { fetchFailureCount: number }
  }) => number | false
  refetchIntervalInBackground: false
}

function toInterval(
  query: { state: { fetchFailureCount: number } },
  base: number,
  enabled: boolean,
  visible: boolean,
): number | false {
  if (!enabled || !visible) return false
  if (query.state.fetchFailureCount >= POLLING_MAX_FAILURES) return false
  return base
}

export function usePollingOptions({ intervalMs = DEFAULT_POLLING_MS, enabled = true }: PollingOptions = {}): PollingProps {
  const visible = useDocumentVisible()

  return useMemo<PollingProps>(
    () => ({
      refetchInterval: (query) => toInterval(query, intervalMs, enabled, visible),
      refetchIntervalInBackground: false,
    }),
    [intervalMs, enabled, visible],
  )
}