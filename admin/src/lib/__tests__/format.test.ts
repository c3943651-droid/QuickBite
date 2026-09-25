import { describe, expect, it } from "vitest"
import { formatCurrency, formatDate, formatDateTime, formatShortDay } from "../format"

describe("formatCurrency", () => {
  it("formatea montos en pesos mexicanos", () => {
    expect(formatCurrency(1234.5)).toBe("$1,234.50")
    expect(formatCurrency(0)).toBe("$0.00")
  })
})

describe("formatDate", () => {
  it("formatea fechas a dd/mm/aaaa", () => {
    expect(formatDate(new Date(2026, 8, 17))).toBe("17/09/2026")
  })

  it("acepta fechas ISO con formato correcto", () => {
    expect(formatDate("2026-09-17")).toMatch(/^\d{2}\/\d{2}\/\d{4}$/)
  })
})

describe("formatDateTime", () => {
  it("incluye la fecha y la hora", () => {
    const result = formatDateTime(new Date(2026, 8, 17, 13, 5))
    expect(result).toMatch(/^\d{2}\/\d{2}\/\d{4}/)
    expect(result).toMatch(/:\d{2}/)
  })
})

describe("formatShortDay", () => {
  it("formatea una fecha ISO a dd/mm", () => {
    expect(formatShortDay("2026-09-17")).toBe("17/09")
  })
})