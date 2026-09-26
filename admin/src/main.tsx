import { StrictMode, Suspense, lazy } from "react"
import { createRoot } from "react-dom/client"
import { QueryClient, QueryClientProvider } from "@tanstack/react-query"
import { BrowserRouter, Navigate, Route, Routes, useLocation } from "react-router-dom"
import { Toaster } from "sonner"
import "./index.css"
import { AppLayout } from "@/components/layout/app-layout"
import { AppErrorBoundary } from "@/components/common/error-boundary"
import { AuthProvider } from "@/lib/session/auth-context"
import { RequireAuth } from "@/lib/session/require-auth"

const LoginPage = lazy(() => import("@/app/login/page"))
const DashboardPage = lazy(() => import("@/app/dashboard/page"))
const OrdersPage = lazy(() => import("@/app/orders/page"))
const ProductsPage = lazy(() => import("@/app/products/page"))
const DeliveryPersonsPage = lazy(() => import("@/app/delivery-persons/page"))
const UsersPage = lazy(() => import("@/app/users/page"))
const CategoriesPage = lazy(() => import("@/app/categories/page"))
const InventoryPage = lazy(() => import("@/app/inventory/page"))
const ReportsPage = lazy(() => import("@/app/reports/page"))
const SalesByDayReportPage = lazy(() => import("@/app/reports/sales-by-day/page"))
const TopProductsReportPage = lazy(() => import("@/app/reports/top-products/page"))
const TopClientsReportPage = lazy(() => import("@/app/reports/top-clients/page"))
const DeliveryPerformanceReportPage = lazy(() => import("@/app/reports/delivery-performance/page"))
const AuditPage = lazy(() => import("@/app/audit/page"))
const ConfigPage = lazy(() => import("@/app/config/page"))
const ProfilePage = lazy(() => import("@/app/profile/page"))
const NotFoundPage = lazy(() => import("@/app/not-found/page"))

const queryClient = new QueryClient()

function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route element={<RequireAuth />}>
        <Route element={<AppLayout />}>
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/orders" element={<OrdersPage />} />
          <Route path="/products" element={<ProductsPage />} />
          <Route path="/categories" element={<CategoriesPage />} />
          <Route path="/inventory" element={<InventoryPage />} />
          <Route path="/users" element={<UsersPage />} />
          <Route path="/delivery-persons" element={<DeliveryPersonsPage />} />
          <Route path="/reports" element={<ReportsPage />} />
          <Route path="/reports/sales-by-day" element={<SalesByDayReportPage />} />
          <Route path="/reports/top-products" element={<TopProductsReportPage />} />
          <Route path="/reports/top-clients" element={<TopClientsReportPage />} />
          <Route path="/reports/delivery-performance" element={<DeliveryPerformanceReportPage />} />
          <Route path="/audit" element={<AuditPage />} />
          <Route path="/config" element={<ConfigPage />} />
          <Route path="/profile" element={<ProfilePage />} />
          <Route path="/" element={<Navigate to="/dashboard" replace />} />
        </Route>
      </Route>
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  )
}

function AppRoot() {
  const location = useLocation()
  return (
    <AppErrorBoundary resetKey={location.pathname}>
      <Suspense fallback={null}>
        <AppRoutes />
      </Suspense>
      <Toaster richColors position="top-center" />
    </AppErrorBoundary>
  )
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <AppRoot />
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>,
)