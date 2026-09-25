import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import { exportCSV } from "../csv"

interface FakeAnchor {
  href: string
  download: string
  click: ReturnType<typeof vi.fn>
}

class FakeBlob {
  static last: FakeBlob | undefined
  parts: (string | ArrayBuffer | Blob)[]
  type: string

  constructor(parts: (string | ArrayBuffer | Blob)[], options?: { type?: string }) {
    FakeBlob.last = this
    this.parts = parts
    this.type = options?.type ?? ""
  }
}

describe("exportCSV", () => {
  let anchor: FakeAnchor

  beforeEach(() => {
    anchor = { href: "", download: "", click: vi.fn() }
    vi.stubGlobal("document", { createElement: () => anchor })
    vi.stubGlobal("Blob", class extends FakeBlob {})
    URL.createObjectURL = vi.fn(() => "blob:fake")
    URL.revokeObjectURL = vi.fn()
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it("genera csv con BOM, cabecera y filas", () => {
    exportCSV("reporte.csv", ["Nombre", "Precio"], [
      ["Hamburguesa", 89.5],
      ["Refresco", null],
    ])

    const content = FakeBlob.last!.parts[0] as string

    expect(content.startsWith("\uFEFF")).toBe(true)
    expect(content).toContain("Nombre,Precio\n")
    expect(content).toContain("Hamburguesa,89.5")
    expect(content).toContain("Refresco,")
  })

  it("escapa comas, saltos de línea y comillas", () => {
    exportCSV("x.csv", ["a", "b"], [
      [`con, coma`, `con "comillas"`],
      ["multi\nlinea", "sano"],
    ])

    const content = FakeBlob.last!.parts[0] as string
    const body = content.slice(1)

    expect(body).toContain('"con, coma","con ""comillas"""')
    expect(body).toContain('"multi\nlinea",sano')
  })

  it("descarga el archivo con el nombre indicado", () => {
    exportCSV("ventas.csv", ["Día"], [["2026-09-25"]])

    expect(anchor.download).toBe("ventas.csv")
    expect(anchor.href).toBe("blob:fake")
    expect(anchor.click).toHaveBeenCalledOnce()
    expect(URL.createObjectURL).toHaveBeenCalledOnce()
    expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:fake")
  })
})