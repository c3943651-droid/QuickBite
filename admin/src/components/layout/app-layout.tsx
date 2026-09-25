import { useState, useSyncExternalStore } from "react"
import { Outlet } from "react-router-dom"
import { WifiOff } from "lucide-react"
import { cn } from "cn"
import { AppSidebar } from "./app-sidebar"
import { AppHeader } from "./app-header"

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
  const [isOpen, setIsOpen] = useState(true)

  return (
    <div className="min-h-screen bg-background">
      <AppSidebar isOpen={isOpen} onClose={() => setIsOpen(false)} />
      <div
        className={cn(
          "flex min-h-screen flex-col transition-all duration-300 ease-in-out",
          isOpen ? "lg:pl-64" : "lg:pl-0",
        )}
      >
        {!isOnline ? (
          <div className="flex items-center justify-center gap-2 border-b bg-zinc-900 px-4 py-1.5 text-sm font-medium text-white">
            <WifiOff className="size-4" />
            Sin conexión — los cambios no se sincronizarán
          </div>
        ) : null}
        <AppHeader onToggleSidebar={() => setIsOpen((value) => !value)} />
        <main className="flex-1 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}