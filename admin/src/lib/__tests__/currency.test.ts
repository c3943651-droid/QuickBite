import { describe, expect, it } from "vitest"
import { formatAmountInput, parseAmount, sanitizeAmount } from "../currency"

describe("sanitizeAmount", () => {
  it("conserva digitos y descarta demas caracteres", () => {
    expect(sanitizeAmount("abc12.x34")).toBe("12.34")
  })

  it("soporta coma como separador decimal", () => {
    expect(sanitizeAmount("75,5")).toBe("75.5")
  })

  it("limita a dos decimales", () => {
    expect(sanitizeAmount("8.999")).toBe("8.99")
  })

  it("descarta puntos repetidos", () => {
    expect(sanitizeAmount("1.2.3")).toBe("1.23")
  })

  it("deja vacio un punto o cadena vacia", () => {
    expect(sanitizeAmount(".")).toBe("")
    expect(sanitizeAmount("")).toBe("")
  })
})

describe("parseAmount", () => {
  it("convierte cadena vacia o punto al monton 0", () => {
    expect(parseAmount("")).toBe(0)
    expect(parseAmount(".")).toBe(0)
  })

  it("convierte cadenas validas", () => {
    expect(parseAmount("12.34")).toBe(12.34)
    expect(parseAmount("0.5")).toBe(0.5)
  })
})

describe("formatAmountInput", () => {
  it("forma dos decimales para montos mayores a 0", () => {
    expect(formatAmountInput(109.99)).toBe("109.99")
    expect(formatAmountInput(0.5)).toBe("0.50")
  })

  it("deja vacio el campo para 0 o valores no numericos", () => {
    expect(formatAmountInput(0)).toBe("")
    expect(formatAmountInput(Number.NaN)).toBe("")
  })
})