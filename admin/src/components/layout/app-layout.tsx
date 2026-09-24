import { useSyncExternalStore } from "react"
import { Outlet } from "react-router-dom"
import { WifiOff } from "lucide-react"
import { AppHeader } from "./app-header"
import { AppSidebar } from "./app-sidebar"

function subscribe(callback: () => void): () => void {
  window.addEventListener("online", callback)
  window.addEventListener("offline", callback)
  return () => {
    window.removeEventListener("online", callback)
    window.removeEventListener("offline", callback)
  }
}

function useOnlineStatus(): boolean {
  return useSyncExternalStore(subscribe, () => navigator.onLine, () => true)
}

export function AppLayout() {
  const isOnline = useOnlineStatus()

  return (
    <div className="min-h-screen bg-muted/30">
      <AppSidebar />
      <div className="flex min-h-screen flex-col lg:pl-64">
        {!isOnline ? (
          <div className="flex items-center justify-center gap-2 border-b bg-amber-500/90 px-4 py-1.5 text-sm font-medium text-white">
            <WifiOff className="size-4" />
            Sin conexión — los cambios no se sincronizarán
          </div>
        ) : null}
        <AppHeader />
        <main className="flex-1 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}