export function sanitizeAmount(raw: string): string {
  const normalized = raw.replace(/,/g, ".")
  const cleaned = normalized.replace(/[^\d.]/g, "")
  const [integerPart, ...decimalParts] = cleaned.split(".")
  const decimals = decimalParts.join("").slice(0, 2)
  if (decimals.length > 0) {
    return `${integerPart.length > 0 ? integerPart : "0"}.${decimals}`
  }
  return integerPart
}

export function parseAmount(sanitized: string): number {
  if (sanitized === "" || sanitized === ".") return 0
  const value = Number(sanitized)
  return Number.isFinite(value) ? value : 0
}

export function formatAmountInput(value: number): string {
  return value > 0 ? value.toFixed(2) : ""
}