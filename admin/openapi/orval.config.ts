import { defineConfig } from 'orval'

export default defineConfig({
  quickbite: {
    input: {
      target: './swagger.json',
      filters: {
        tags: [
          'Auth',
          'Users',
          'Catalog',
          'AdminAudit',
          'AdminCatalog',
          'AdminConfig',
          'AdminDashboard',
          'AdminDelivery',
          'AdminOrders',
          'AdminReports',
          'AdminUser',
        ],
      },
    },
    output: {
      target: '../src/lib/api/generated',
      client: 'react-query',
      mode: 'tags-split',
      httpClient: 'axios',
      clean: true,
      override: {
        mutator: {
          path: '../src/lib/api/custom-instance.ts',
          name: 'customInstance',
        },
        query: {
          useQuery: true,
          useInfinite: true,
          useMutation: true,
        },
      },
    },
  },
})