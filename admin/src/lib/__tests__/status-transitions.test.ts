import { describe, expect, it, vi } from "vitest"
import {
  getNextTransition,
  isTerminal,
  NEXT_TRANSITIONS,
} from "@/lib/orders/status-transitions"

vi.mock("@/lib/api/admin/orders", () => ({
  ORDER_STATUS_VALUES: {
    Pendiente: 1,
    Confirmado: 2,
    Preparando: 3,
    Listo: 4,
    EnCamino: 5,
    Entregado: 6,
    Cancelado: 7,
  },
}))

describe("isTerminal", () => {
  it("reconoce estados terminales", () => {
    expect(isTerminal("Entregado")).toBe(true)
    expect(isTerminal("Cancelado")).toBe(true)
  })

  it("rechaza estados no terminales", () => {
    expect(isTerminal("Pendiente")).toBe(false)
    expect(isTerminal("Preparando")).toBe(false)
  })
})

describe("getNextTransition", () => {
  it("devuelve la transición válida para cada estado", () => {
    const cases = [
      ["Pendiente", "Confirmar", 2],
      ["Confirmado", "Pasar a preparación", 3],
      ["Preparando", "Marcar listo", 4],
      ["Listo", "Enviar a reparto", 5],
      ["EnCamino", "Marcar entregado", 6],
    ] as const

    for (const [from, label, value] of cases) {
      const next = getNextTransition(from)
      expect(next).toBeDefined()
      expect(next?.label).toBe(label)
      expect(next?.value).toBe(value)
    }
  })

  it("no ofrece transición para estados terminales o desconocidos", () => {
    expect(getNextTransition("Entregado")).toBeUndefined()
    expect(getNextTransition("Cancelado")).toBeUndefined()
    expect(getNextTransition("Desconocido")).toBeUndefined()
  })
})

describe("NEXT_TRANSITIONS", () => {
  it("solo apunta a estados existentes", () => {
    const valid = new Set([1, 2, 3, 4, 5, 6, 7])
    for (const transition of Object.values(NEXT_TRANSITIONS)) {
      if (!transition) continue
      expect(valid.has(transition.value)).toBe(true)
    }
  })
})