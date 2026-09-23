import { defineConfig } from 'orval'

export default defineConfig({
  quickbite: {
    input: {
      target: 'https://quickbite-n1bk.onrender.com/swagger/v1/swagger.json',
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