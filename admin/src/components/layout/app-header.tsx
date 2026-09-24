import { useNavigate } from "react-router-dom"
import { LogOut, UserRound } from "lucide-react"
import { toast } from "sonner"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { useAuth } from "@/lib/auth/auth-context"

function initials(name: string | undefined): string {
  const parts = (name ?? "?").trim().split(/\s+/)
  const first = parts[0]?.[0] ?? "?"
  const last = parts[1]?.[0]
  return last ? `${first}${last}`.toUpperCase() : first.toUpperCase()
}

export function AppHeader() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout()
    toast.success("Sesión cerrada")
    navigate("/login", { replace: true })
  }

  return (
    <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b bg-background px-6">
      <span className="text-lg font-semibold lg:hidden">QuickBite Admin</span>
      <span className="text-muted-foreground text-sm hidden lg:block">
        Panel de administración
      </span>
      <DropdownMenu>
        <DropdownMenuTrigger asChild>
          <Button variant="ghost" className="gap-2 px-2">
            <Avatar size="sm">
              <AvatarFallback>{initials(user?.nombre)}</AvatarFallback>
            </Avatar>
            <span className="text-sm font-medium hidden sm:block">{user?.nombre}</span>
          </Button>
        </DropdownMenuTrigger>
        <DropdownMenuContent align="end" className="w-56">
          <DropdownMenuLabel>
            <div className="flex flex-col">
              <span>{user?.nombre}</span>
              <span className="text-muted-foreground text-xs font-normal">
                {user?.email}
              </span>
            </div>
          </DropdownMenuLabel>
          <DropdownMenuSeparator />
          <DropdownMenuItem onSelect={() => navigate("/profile")}>
            <UserRound className="mr-2 size-4" />
            Mi perfil
          </DropdownMenuItem>
          <DropdownMenuItem onSelect={handleLogout}>
            <LogOut className="mr-2 size-4" />
            Cerrar sesión
          </DropdownMenuItem>
        </DropdownMenuContent>
      </DropdownMenu>
    </header>
  )
}