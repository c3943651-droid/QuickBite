/**
 * @vitest-environment jsdom
 */
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { cleanup, render, screen } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"
import type { DeliveryPersonListItem } from "@/lib/api/admin/orders"
import { DeliveryPersonFormDialog } from "../delivery-person-form-dialog"

vi.mock("@/lib/api/admin/delivery-persons", async (importOriginal) => {
  const actual =
    await importOriginal<typeof import("@/lib/api/admin/delivery-persons")>()
  return {
    ...actual,
    useAvailableDeliveryUsers: () => ({
      data: [],
      isLoading: false,
      isError: false,
      refetch: vi.fn(),
    }),
    useCreateDeliveryPerson: () => ({ mutateAsync: vi.fn(), isPending: false }),
    useUpdateDeliveryPerson: () => ({ mutateAsync: vi.fn(), isPending: false }),
  }
})

afterEach(cleanup)

const REPARTIDOR_SIN_CONTACTO: DeliveryPersonListItem = {
  usuarioId: "f82660eb-93f1-4902-bbb8-db489159cb25",
  nombre: "Carlos Pérez",
  email: "carlosshupan427@gmail.com",
  telefono: null,
  estadoDisponibilidad: "inactivo",
  vehiculo: null,
  entregasCompletadas: 0,
  fechaAlta: "2026-09-29T15:34:23.801876",
}

function renderDialog(repartidor: DeliveryPersonListItem | null) {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  })
  return render(
    <QueryClientProvider client={queryClient}>
      <DeliveryPersonFormDialog
        open
        onOpenChange={vi.fn()}
        repartidor={repartidor}
      />
    </QueryClientProvider>,
  )
}

describe("DeliveryPersonFormDialog", () => {
  it("abre el formulario de edición cuando telefono y vehiculo son null", async () => {
    renderDialog(REPARTIDOR_SIN_CONTACTO)
    expect(await screen.findByText("Editar repartidor")).toBeTruthy()
    expect(screen.getByText("Carlos Pérez")).toBeTruthy()
  })

  it("muestra el vehículo vacío y editable cuando no hay vehículo registrado", async () => {
    renderDialog(REPARTIDOR_SIN_CONTACTO)
    const input = await screen.findByPlaceholderText(
      "Ej. Moto Honda 125 · ABC-123",
    )
    expect((input as HTMLInputElement).value).toBe("")
  })

  it("sigue abriendo el formulario de creación", async () => {
    renderDialog(null)
    expect(await screen.findByText("Nuevo repartidor")).toBeTruthy()
    expect(
      await screen.findByText(
        "No hay usuarios con rol repartidor pendientes de registrar.",
      ),
    ).toBeTruthy()
  })
})
