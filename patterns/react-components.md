# React Component Patterns

## Feature Module Structure

```
features/
└── [feature-name]/
    ├── api/               # TanStack Query hooks
    │   ├── use-get-[resource].ts
    │   └── use-update-[resource].ts
    ├── components/        # Feature-specific components
    │   ├── [component].tsx
    │   └── [sub-component].tsx
    ├── hooks/             # Custom hooks (non-API)
    │   └── use-[behavior].ts
    ├── views/             # Page-level client components
    │   └── [feature]-client.tsx
    └── utils/             # Pure helper functions
        └── [helpers].ts
```

## Component Pattern

```typescript
"use client"

import React, { useMemo } from "react"
import { useTheme } from "next-themes"

type MyComponentProps = {
  items: Item[]
  isRefetching?: boolean
  onSelect?: (id: string) => void
}

const MyComponent: React.FC<MyComponentProps> = ({
  items,
  isRefetching = false,
  onSelect,
}) => {
  const { theme } = useTheme()
  const isDark = theme === "dark"

  // Memoize expensive computations
  const processed = useMemo(() => items.map(transform), [items])

  if (!items.length) return <EmptyState />

  return (
    <div className="border border-border rounded-md p-2 bg-background/50">
      {isRefetching && <Loader2 className="h-3 w-3 animate-spin" />}
      {processed.map((item) => (
        <ItemCard key={item.id} item={item} onSelect={onSelect} />
      ))}
    </div>
  )
}

export default MyComponent
```

## State Management (3 Layers)

### 1. Server State: TanStack Query

All API data. See [tanstack-query.md](tanstack-query.md).

### 2. UI State: Zustand

Modals, drawers, selection state:

```typescript
import { create } from "zustand"

type ModalState = {
  isOpen: boolean
  itemId: string | null
  onOpen: (id: string | null) => void
  onClose: () => void
}

export const useItemModal = create<ModalState>((set) => ({
  isOpen: false,
  itemId: null,
  onOpen: (itemId) => set({ isOpen: true, itemId }),
  onClose: () => set({ isOpen: false, itemId: null }),
}))
```

### 3. Filter State: URL Params

Filters, pagination, sort persisted in URL:

```typescript
const searchParams = useSearchParams()
const router = useRouter()
const pathname = usePathname()

const search = searchParams.get("search") || undefined
const page = searchParams.get("page") || undefined

const updateParams = useCallback((updates: Record<string, string | null>) => {
  const params = new URLSearchParams(searchParams.toString())
  Object.entries(updates).forEach(([key, value]) => {
    value === null ? params.delete(key) : params.set(key, value)
  })
  router.push(`${pathname}?${params.toString()}`, { scroll: false })
}, [router, pathname, searchParams])
```

## Form Handling (react-hook-form + Zod)

```typescript
import { useForm } from "react-hook-form"
import { zodResolver } from "@hookform/resolvers/zod"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@scope/ui/form"

const form = useForm<FormValues>({
  resolver: zodResolver(formSchema),
  defaultValues: initialValues,
})

return (
  <Form {...form}>
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <FormField control={form.control} name="fieldName"
        render={({ field }) => (
          <FormItem>
            <FormLabel>Label</FormLabel>
            <FormControl><Input {...field} /></FormControl>
            <FormMessage />
          </FormItem>
        )}
      />
      <Button type="submit" disabled={mutation.isPending}>
        {mutation.isPending ? "Saving..." : "Save"}
      </Button>
    </form>
  </Form>
)
```

## Data Tables (TanStack Table)

```typescript
const columns: ColumnDef<Row>[] = [
  {
    id: "select",
    header: ({ table }) => <Checkbox checked={table.getIsAllPageRowsSelected()} ... />,
    cell: ({ row }) => <Checkbox checked={row.getIsSelected()} ... />,
    enableSorting: false,
  },
  {
    accessorKey: "name",
    header: ({ column }) => <DataTableColumnHeader column={column} title="Name" />,
    cell: ({ row }) => <span>{row.getValue("name")}</span>,
  },
]

// Bulk operations (memoized)
const bulkOps = useMemo(() => [
  { label: "Delete", icon: <Trash />, onClick: (rows) => deleteMutation.mutate(rows) },
], [deleteMutation])

return <DataTable columns={columns} data={data} isLoading={isLoading} bulkOperations={bulkOps} />
```

## Charts (Recharts)

```typescript
<ResponsiveContainer width="100%" height="100%">
  <ComposedChart data={data} syncId="timeseries">
    <CartesianGrid strokeDasharray="3 3" stroke={gridColor} vertical={false} />
    <XAxis dataKey="date" tick={{ fontSize: 10 }} />
    <YAxis />
    <Tooltip contentStyle={{ backgroundColor: isDark ? "#27272a" : "#fff" }} />
    <Area dataKey="band" fill="rgba(59,130,246,0.1)" stroke="none" />
    <Line dataKey="value" stroke="#3b82f6" dot={false} />
  </ComposedChart>
</ResponsiveContainer>
```

Use `syncId` for cross-chart hover sync.

## Loading / Error States

```typescript
if (isLoading) return <Skeleton className="h-64" />
if (error) return <Error message={error?.message || "An error occurred"} className="h-64" />
if (!data?.length) return <EmptyState message="No items found" />
```

## Toast Notifications (Sonner)

```typescript
import { toast } from "sonner"
showSuccessToast({ message: "Saved" })
showErrorToast({ message: "Failed to save" })
showInfoToast({ message: "Processing..." })
```

## Performance Rules

- `useMemo` for derived arrays/objects passed as props
- `useCallback` for event handlers passed to children
- `React.memo` sparingly (only for expensive renders)
- `keepPreviousData` in queries for smooth transitions
- Dynamic imports for heavy components (maps, charts)

## Docs

- [React Hook Form](https://react-hook-form.com/docs/useform)
- [Zod Resolver](https://github.com/react-hook-form/resolvers)
- [TanStack Table](https://tanstack.com/table/latest/docs/introduction)
- [Recharts API](https://recharts.github.io/en-US/api/)
- [Zustand](https://zustand-demo.pmnd.rs/)
- [Sonner Toasts](https://sonner.emilkowal.dev/)
