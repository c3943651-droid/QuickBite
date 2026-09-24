export const queryKeys = {
  dashboard: ["admin", "dashboard"] as const,
  orders: {
    all: ["admin", "orders"] as const,
    list: ["admin", "orders", "list"] as const,
    detail: (id: string) => ["admin", "orders", "detail", id] as const,
    assignees: ["admin", "orders", "assignees"] as const,
  },
  products: {
    all: ["admin", "products"] as const,
    detail: (id: string) => ["admin", "products", "detail", id] as const,
    options: (id: string) => ["admin", "products", "detail", id, "options"] as const,
    priceHistory: (id: string) => ["admin", "products", "detail", id, "price-history"] as const,
  },
  categories: {
    all: ["admin", "categories"] as const,
  },
  inventory: ["admin", "inventory"] as const,
  deliveryPersons: {
    all: ["admin", "delivery-persons"] as const,
    availableUsers: ["admin", "delivery-persons", "available-users"] as const,
    detail: (id: string) => ["admin", "delivery-persons", "detail", id] as const,
    history: (id: string) => ["admin", "delivery-persons", "detail", id, "history"] as const,
  },
  reports: {
    salesByDay: ["admin", "reports", "sales-by-day"] as const,
    topProducts: ["admin", "reports", "top-products"] as const,
    topClients: ["admin", "reports", "top-clients"] as const,
    deliveryPerformance: ["admin", "reports", "delivery-performance"] as const,
  },
  config: {
    all: ["admin", "config"] as const,
  },
  audit: {
    all: ["admin", "audit"] as const,
  },
  notifications: {
    all: ["notifications"] as const,
  },
  profile: {
    all: ["users", "profile"] as const,
    sessions: ["users", "sessions"] as const,
  },
} as const