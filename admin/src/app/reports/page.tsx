import {
  BarChart3,
  CalendarDays,
  Truck,
  Users,
  type LucideIcon,
} from "lucide-react"
import { Link } from "react-router-dom"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"

const reports = [
  {
    to: "/reports/sales-by-day",
    title: "Ventas por día",
    description: "Ingresos y pedidos agrupados por día con rango de fechas.",
    icon: CalendarDays,
  },
  {
    to: "/reports/top-products",
    title: "Productos más vendidos",
    description: "Ranking de productos por unidades vendidas e ingresos.",
    icon: BarChart3,
  },
  {
    to: "/reports/top-clients",
    title: "Clientes top",
    description: "Ranking de clientes por pedidos y gasto total.",
    icon: Users,
  },
  {
    to: "/reports/delivery-performance",
    title: "Desempeño de reparto",
    description: "Entregas completadas y tiempos promedio por repartidor.",
    icon: Truck,
  },
] satisfies Array<{
  to: string
  title: string
  description: string
  icon: LucideIcon
}>

export default function ReportsPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold">Reportes</h1>
        <p className="text-muted-foreground text-sm">
          Reportes de ventas y operación del negocio.
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {reports.map(({ to, title, description, icon: Icon }) => (
          <Link key={to} to={to}>
            <Card className="h-full transition-colors hover:bg-accent/50">
              <CardHeader className="flex flex-row">
                <CardTitle className="text-sm font-medium">{title}</CardTitle>
                <div
                  data-slot="card-action"
                  className="flex size-9 items-center justify-center rounded-lg bg-primary/10 text-primary"
                >
                  <Icon className="size-4" />
                </div>
              </CardHeader>
              <CardContent className="pt-2">
                <p className="text-muted-foreground text-xs">{description}</p>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  )
}