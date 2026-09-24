import { useNavigate } from "react-router-dom"
import { Compass } from "lucide-react"
import { Button } from "@/components/ui/button"

export default function NotFoundPage() {
  const navigate = useNavigate()

  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-6 text-center">
      <div className="flex size-16 items-center justify-center rounded-full bg-muted">
        <Compass className="size-8 text-muted-foreground" />
      </div>
      <div>
        <p className="text-5xl font-bold">404</p>
        <h1 className="mt-2 text-xl font-semibold">Página no encontrada</h1>
        <p className="mt-1 max-w-sm text-sm text-muted-foreground">
          La página que buscas no existe o fue movida. Verifica la dirección o vuelve al
          inicio.
        </p>
      </div>
      <Button onClick={() => navigate("/dashboard", { replace: true })}>
        Volver al inicio
      </Button>
    </div>
  )
}