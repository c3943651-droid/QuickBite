import { Outlet } from "react-router-dom"
import { AppHeader } from "./app-header"
import { AppSidebar } from "./app-sidebar"

export function AppLayout() {
  return (
    <div className="min-h-screen bg-muted/30">
      <AppSidebar />
      <div className="flex min-h-screen flex-col lg:pl-64">
        <AppHeader />
        <main className="flex-1 p-6">
          <Outlet />
        </main>
      </div>
    </div>
  )
}