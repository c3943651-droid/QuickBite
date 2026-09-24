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
} from "lucide-react"
import { cn } from "cn"

const navItems = [
  { to: "/dashboard", label: "Dashboard", icon: LayoutDashboard, end: true },
  { to: "/orders", label: "Pedidos", icon: ShoppingCart, end: true },
  { to: "/products", label: "Productos", icon: Package, end: true },
  { to: "/categories", label: "Categorías", icon: Tags, end: true },
  { to: "/inventory", label: "Inventario", icon: Boxes, end: true },
  { to: "/delivery-persons", label: "Repartidores", icon: Bike, end: true },
  { to: "/reports", label: "Reportes", icon: BarChart3, end: true },
  { to: "/audit", label: "Auditoría", icon: ShieldCheck, end: true },
  { to: "/config", label: "Configuración", icon: Settings, end: true },
] as const

export function AppSidebar() {
  return (
    <aside className="fixed inset-y-0 left-0 z-30 hidden w-64 flex-col border-r bg-background lg:flex">
      <div className="flex h-16 items-center border-b px-6">
        <span className="text-lg font-semibold">QuickBite Admin</span>
      </div>
      <nav className="flex-1 space-y-1 p-3">
        {navItems.map(({ to, label, icon: Icon, end }) => (
          <NavLink
            key={to}
            to={to}
            end={end}
            className={({ isActive }) =>
              cn(
                "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
                isActive
                  ? "bg-accent text-accent-foreground"
                  : "hover:bg-accent/50 hover:text-accent-foreground",
              )
            }
          >
            <Icon className="size-4" />
            {label}
          </NavLink>
        ))}
      </nav>
    </aside>
  )
}