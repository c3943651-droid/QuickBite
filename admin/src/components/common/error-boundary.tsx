import { Component, type ErrorInfo, type ReactNode } from "react"
import { TriangleAlert } from "lucide-react"
import { Button } from "@/components/ui/button"

interface AppErrorBoundaryProps {
  children: ReactNode
  resetKey?: string
}

interface AppErrorBoundaryState {
  hasError: boolean
}

export class AppErrorBoundary extends Component<
  AppErrorBoundaryProps,
  AppErrorBoundaryState
> {
  state: AppErrorBoundaryState = { hasError: false }

  static getDerivedStateFromError(): AppErrorBoundaryState {
    return { hasError: true }
  }

  componentDidCatch(error: Error, info: ErrorInfo): void {
    console.error("Error de aplicación no controlado", error, info)
  }

  componentDidUpdate(prevProps: AppErrorBoundaryProps): void {
    if (this.state.hasError && prevProps.resetKey !== this.props.resetKey) {
      this.setState({ hasError: false })
    }
  }

  render(): ReactNode {
    if (!this.state.hasError) {
      return this.props.children
    }

    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-4 p-6 text-center">
        <div className="flex size-16 items-center justify-center rounded-full bg-destructive/10">
          <TriangleAlert className="size-8 text-destructive" />
        </div>
        <div>
          <h1 className="text-xl font-semibold">Ocurrió un error inesperado</h1>
          <p className="mt-1 max-w-sm text-sm text-muted-foreground">
            Algo salió mal al mostrar esta vista. Recarga la página o vuelve a intentarlo.
          </p>
        </div>
        <Button onClick={() => window.location.reload()}>Recargar página</Button>
      </div>
    )
  }
}