import { Menu } from "lucide-react"
import { UserNav } from "./user-nav"

export function AppHeader({ onToggleSidebar }: { onToggleSidebar: () => void }) {
  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-zinc-200/80 bg-white/80 px-6 backdrop-blur-md">
      <div className="flex items-center gap-2">
        <button
          type="button"
          aria-label="Alternar menú"
          onClick={onToggleSidebar}
          className="flex h-9 w-9 items-center justify-center rounded-lg text-zinc-600 transition-colors duration-200 hover:bg-zinc-100"
        >
          <Menu className="size-5" />
        </button>
        <span className="text-muted-foreground hidden text-sm lg:block">
          Panel de administración
        </span>
      </div>
      <UserNav />
    </header>
  )
}