import { useNavigate } from "react-router-dom"
import { ChevronDown, LogOut, UserRound } from "lucide-react"
import { toast } from "sonner"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { useAuth } from "@/lib/session/auth-context"

function initials(name: string | undefined): string {
  const parts = (name ?? "?").trim().split(/\s+/)
  const first = parts[0]?.[0] ?? "?"
  const last = parts[1]?.[0]
  return last ? `${first}${last}`.toUpperCase() : first.toUpperCase()
}

export function UserNav() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()

  async function handleLogout() {
    await logout()
    toast("Sesión cerrada", {
      icon: <LogOut className="size-4 text-emerald-700" />,
      className:
        "w-auto! max-w-max! items-center! gap-2! rounded-full! border! border-emerald-200! bg-emerald-50/80! px-4! py-2! text-sm! font-medium! text-emerald-800! shadow-sm!",
    })
    navigate("/login", { replace: true })
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <button className="flex cursor-pointer items-center gap-2.5 rounded-lg p-1.5 transition-colors duration-200 hover:bg-zinc-100">
          <span className="flex h-8 w-8 items-center justify-center rounded-full bg-zinc-900 text-xs font-semibold text-white">
            {initials(user?.nombre)}
          </span>
          <span className="hidden text-sm font-medium text-zinc-700 sm:block">
            {user?.nombre ?? "Administrador"}
          </span>
          <ChevronDown className="text-zinc-400 size-3.5" />
        </button>
      </DropdownMenuTrigger>
      <DropdownMenuContent
        align="end"
        className="min-w-[220px] rounded-xl border border-zinc-200 bg-white p-1.5 shadow-xl shadow-zinc-200/50"
      >
        <DropdownMenuLabel className="mb-1 rounded-lg bg-zinc-50 px-3 py-2.5">
          <div className="flex flex-col gap-0.5">
            <span className="text-sm font-semibold text-zinc-900">
              {user?.nombre ?? "Administrador"}
            </span>
            <span className="text-xs text-zinc-500">{user?.email}</span>
          </div>
        </DropdownMenuLabel>
        <DropdownMenuSeparator className="my-1.5" />
        <DropdownMenuItem
          onSelect={() => navigate("/profile")}
          className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-sm text-zinc-700 transition-colors duration-200 hover:bg-zinc-100"
        >
          <UserRound className="size-4 text-zinc-400" />
          Mi perfil
        </DropdownMenuItem>
        <DropdownMenuItem
          onSelect={handleLogout}
          className="flex cursor-pointer items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium text-rose-600 transition-colors duration-200 hover:bg-rose-50 hover:text-rose-700"
        >
          <LogOut className="size-4" />
          Cerrar sesión
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  )
}