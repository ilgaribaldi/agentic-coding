# TanStack Query Patterns

## Hook Conventions

### Query Hook (GET)

```typescript
// features/[domain]/api/use-get-[resource].ts
import { useQuery, keepPreviousData } from "@tanstack/react-query"
import type { InferResponseType } from "hono/client"

type ResponseType = InferResponseType<typeof client.api.domain.$get>

export const useGetResource = ({
  id,
  enabled = true,
}: {
  id: string
  enabled?: boolean
}) => {
  return useQuery<ResponseType>({
    queryKey: ["resource", id],
    queryFn: async () => {
      const response = await client.api.domain[":id"].$get({ param: { id } })
      if (!response.ok) throw new Error("Failed to fetch")
      return await response.json()
    },
    enabled: enabled && !!id,
  })
}
```

### Mutation Hook (POST/PATCH/DELETE)

```typescript
// features/[domain]/api/use-update-[resource].ts
export const useUpdateResource = ({ onSuccess, onError }: Callbacks = {}) => {
  const queryClient = useQueryClient()

  return useMutation<ResponseType, Error, { id: string; json: RequestType }>({
    mutationFn: async ({ id, json }) => {
      const response = await client.api.domain[":id"].$patch({ param: { id }, json })
      if (!response.ok) {
        const errorData = await response.json()
        throw new Error((errorData as any).error || "Failed to update")
      }
      return await response.json()
    },
    onSuccess: (data) => {
      showSuccessToast({ message: "Updated successfully" })
      queryClient.invalidateQueries({ queryKey: ["resource"] })
      onSuccess?.(data)
    },
    onError: (error) => {
      showErrorToast({ message: error.message || "Failed to update" })
      onError?.(error)
    },
  })
}
```

## Query Key Conventions

Hierarchical, include all variables used in `queryFn`:

```typescript
// Simple
["resource", id]

// With filters
["resource-list", orgId, { search, sort, page }]

// Nested (multiple filter dimensions)
["<resource>-history", userId, status, startDate, endDate]

// Factory pattern for complex domains
const QUERY_KEYS = {
  all: (orgId: string) => ["domain", orgId] as const,
  list: (orgId: string, filters: Filters) => [...QUERY_KEYS.all(orgId), "list", filters] as const,
  detail: (orgId: string, id: string) => [...QUERY_KEYS.all(orgId), "detail", id] as const,
}
```

## Cache Configuration

```typescript
// Stable data (changes only on explicit sync)
staleTime: 5 * 60 * 1000,  // 5 min
gcTime: 10 * 60 * 1000,    // 10 min

// Show previous results while refetching
placeholderData: keepPreviousData

// Conditional execution
enabled: enabled && !!id
```

## Invalidation Patterns

```typescript
// After mutation — invalidate related queries
queryClient.invalidateQueries({ queryKey: ["resource"] })

// Multiple related invalidations
queryClient.invalidateQueries({ queryKey: ["<resource>-table"] })
queryClient.invalidateQueries({ queryKey: ["<resource>-map"] })
queryClient.invalidateQueries({ queryKey: ["<resource>-summary"] })

// On org change — clear everything
queryClient.cancelQueries({ queryKey: ["domain"] })
queryClient.removeQueries({ queryKey: ["domain"] })
```

## Shared Hooks (Cross-App)

```typescript
// packages/api/src/hooks/[domain].ts
// Used by mobile, desktop, and web
export const useGetResource = ({ id, enabled = true }) => {
  const apiClient = useApiClient()  // Platform-specific HTTP client
  return useQuery({
    queryKey: ["resource", id],
    queryFn: () => apiClient(`/resource/${id}`),
    enabled: enabled && !!id,
  })
}
```

## Infinite Queries (Pagination)

```typescript
export const useGetResources = (filters) => {
  return useInfiniteQuery({
    queryKey: ["resources", filters],
    queryFn: async ({ pageParam = 1 }) => {
      const res = await client.api.resources.$get({ query: { ...filters, page: pageParam } })
      return await res.json()
    },
    getNextPageParam: (lastPage) => lastPage.pagination.nextPage,
    initialPageParam: 1,
  })
}

// Flatten pages
const allItems = data?.pages.flatMap((page) => page.data)
```

## Anti-Patterns

- Never use `satisfies` on Hono route types — breaks `InferResponseType`
- Always include `enabled` guard for optional params
- Don't cache-bust by adding timestamps to query keys
- Don't mix query + mutation in the same hook

## Docs

- [useQuery](https://tanstack.com/query/v5/docs/framework/react/reference/useQuery)
- [useMutation](https://tanstack.com/query/v5/docs/react/reference/useMutation)
- [Query Keys](https://tanstack.com/query/v5/docs/react/guides/query-keys)
- [Invalidation](https://tanstack.com/query/v5/docs/react/guides/query-invalidation)
- [Optimistic Updates](https://tanstack.com/query/v5/docs/react/guides/optimistic-updates)
- [Infinite Queries](https://tanstack.com/query/v5/docs/react/guides/infinite-queries)
