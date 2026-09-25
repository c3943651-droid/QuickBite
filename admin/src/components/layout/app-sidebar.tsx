import { NavLink } from "react-router-dom"
import {
  BarChart3,
  Bike,
  Boxes,
  LayoutDashboard,
  Package,
  Settings,
  ShieldCheck,
  ShoppingCart,
  Tags,
  X,
} from "lucide-react"
import { cn } from "cn"
import { Brand } from "@/components/common/brand"

const navSections = [
  {
    title: "General",
    items: [
      { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard, end: true },
      { to: "/orders", label: "Pedidos", icon: ShoppingCart, end: true },
      { to: "/products", label: "Productos", icon: Package, end: true },
      { to: "/categories", label: "Categorías", icon: Tags, end: true },
      { to: "/inventory", label: "Inventario", icon: Boxes, end: true },
    ],
  },
  {
    title: "Operación",
    items: [
      { to: "/delivery-persons", label: "Repartidores", icon: Bike, end: true },
      { to: "/reports", label: "Reportes", icon: BarChart3, end: true },
      { to: "/audit", label: "Auditoría", icon: ShieldCheck, end: true },
      { to: "/config", label: "Configuración", icon: Settings, end: true },
    ],
  },
] as const

type NavItemProps = {
  to: string
  end: boolean
  label: string
  icon: typeof LayoutDashboard
  onNavigate?: () => void
}

function NavItem({ to, end, label, icon: Icon, onNavigate }: NavItemProps) {
  return (
    <NavLink
      to={to}
      end={end}
      onClick={onNavigate}
      className={({ isActive }) =>
        cn(
          "relative flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors duration-200",
          isActive
            ? "bg-zinc-800 font-medium text-white"
            : "text-zinc-400 hover:bg-white/5 hover:text-zinc-100",
        )
      }
    >
      {({ isActive }) => (
        <>
          {isActive ? (
            <span className="absolute top-1/2 left-0 h-4 w-0.5 -translate-y-1/2 rounded-full bg-zinc-200" />
          ) : null}
          <Icon className="size-4 shrink-0" />
          <span className="truncate">{label}</span>
        </>
      )}
    </NavLink>
  )
}

function SidebarNav({ onNavigate }: { onNavigate?: () => void }) {
  return (
    <nav className="flex-1 space-y-6 overflow-y-auto p-3">
      {navSections.map((section) => (
        <div key={section.title} className="space-y-1">
          <p className="px-3 pb-1 text-[11px] font-semibold uppercase tracking-wider text-sidebar-foreground/40">
            {section.title}
          </p>
          {section.items.map((item) => (
            <NavItem key={item.to} {...item} onNavigate={onNavigate} />
          ))}
        </div>
      ))}
    </nav>
  )
}

export function AppSidebar({
  isOpen,
  onClose,
}: {
  isOpen: boolean
  onClose: () => void
}) {
  function handleNavigate() {
    if (!window.matchMedia("(min-width: 1024px)").matches) {
      onClose()
    }
  }

  return (
    <>
      {isOpen ? (
        <div
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden"
          onClick={onClose}
        />
      ) : null}
      <aside
        className={cn(
          "fixed inset-y-0 left-0 z-50 flex w-64 flex-col border-r border-sidebar-border bg-sidebar transition-transform duration-300 ease-in-out lg:z-30",
          isOpen ? "translate-x-0" : "-translate-x-full",
        )}
      >
        <div className="flex h-16 shrink-0 items-center border-b border-sidebar-border px-4">
          <Brand />
          <button
            type="button"
            aria-label="Cerrar menú"
            onClick={onClose}
            className="ml-auto flex h-8 w-8 items-center justify-center rounded-lg text-zinc-400 transition-colors duration-200 hover:bg-white/5 hover:text-zinc-100 lg:hidden"
          >
            <X className="size-4" />
          </button>
        </div>
        <SidebarNav onNavigate={handleNavigate} />
      </aside>
    </>
  )
}