const CURRENCY_FORMATTER = new Intl.NumberFormat("es-MX", {
  style: "currency",
  currency: "MXN",
})

const DATE_FORMATTER = new Intl.DateTimeFormat("es-MX", {
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
})

const DATETIME_FORMATTER = new Intl.DateTimeFormat("es-MX", {
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
  hour: "2-digit",
  minute: "2-digit",
})

export function formatCurrency(value: number): string {
  return CURRENCY_FORMATTER.format(value)
}

export function formatDate(value: string | Date): string {
  return DATE_FORMATTER.format(new Date(value))
}

export function formatDateTime(value: string | Date): string {
  return DATETIME_FORMATTER.format(new Date(value))
}

export function formatShortDay(value: string): string {
  const date = new Date(`${value}T00:00:00`)
  return new Intl.DateTimeFormat("es-MX", { day: "2-digit", month: "2-digit" }).format(date)
}