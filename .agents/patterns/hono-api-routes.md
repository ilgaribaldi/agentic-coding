# Hono API Routes

## Two-File Pattern

**`route.ts`** — Middleware + handler exports:

```typescript
import { Hono } from "hono"
import { handle } from "hono/vercel"
import { clerkMiddleware } from "@hono/clerk-auth"
import domain from "./domain"

const app = new Hono().basePath("/api/domain")

app.use("*", clerkMiddleware({
  secretKey: process.env.CLERK_SECRET_KEY,
  publishableKey: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
}))

const routes = app.route("/", domain)
export type DomainAppType = typeof routes  // Export for client type inference

export const GET = handle(app)
export const POST = handle(app)
export const PATCH = handle(app)
export const DELETE = handle(app)
```

**`domain.ts`** — Route handlers:

```typescript
import { Hono } from "hono"
import { zValidator } from "@hono/zod-validator"
import { getAuth } from "@hono/clerk-auth"
import { db } from "@/db/drizzle"
import { z } from "zod"

const app = new Hono()
  .get("/", async (c) => {
    const auth = getAuth(c)
    if (!auth?.userId || !auth?.orgId) {
      return c.json({ error: "Unauthorized" }, 401)
    }

    const results = await db.select().from(table).where(eq(table.orgId, auth.orgId))
    return c.json({ data: results })
  })
  .post(
    "/",
    zValidator("json", z.object({
      name: z.string().min(1),
      value: z.number(),
    })),
    async (c) => {
      const auth = getAuth(c)
      if (!auth?.userId || !auth?.orgId) {
        return c.json({ error: "Unauthorized" }, 401)
      }

      const body = c.req.valid("json")
      const [result] = await db.insert(table).values({ ...body, orgId: auth.orgId }).returning()
      return c.json({ data: result })
    },
  )

export default app
```

## Key Patterns

### Auth Guard (Every Route)

```typescript
const auth = getAuth(c)
if (!auth?.userId || !auth?.orgId) {
  return c.json({ error: "Unauthorized" }, 401)
}
```

### Zod Validation

```typescript
// Query params
.get("/search", zValidator("query", z.object({
  q: z.string().optional(),
  page: z.coerce.number().optional().default(1),
  limit: z.coerce.number().optional().default(20),
})), async (c) => {
  const { q, page, limit } = c.req.valid("query")
})

// JSON body
.post("/", zValidator("json", createSchema), async (c) => {
  const body = c.req.valid("json")
})

// URL params
.get("/:id", zValidator("param", z.object({ id: z.string() })), async (c) => {
  const { id } = c.req.valid("param")
})
```

### Error Handling

```typescript
try {
  const [result] = await db.select().from(table).where(eq(table.id, id))
  if (!result) return c.json({ error: "Not found" }, 404)
  return c.json({ data: result })
} catch (error) {
  console.error("Error fetching:", error)
  return c.json({ error: "Internal server error" }, 500)
}
```

### Parallel Queries

```typescript
const [limits, locations, stats] = await Promise.all([
  db.select().from(usageLimits).where(eq(usageLimits.orgId, orgId)),
  db.select({ count: count() }).from(locations).where(eq(locations.orgId, orgId)),
  db.select().from(stats).where(eq(stats.orgId, orgId)),
])
```

### Type-Safe Client (Hono RPC)

```typescript
// Server: export type
export type AppType = typeof routes

// Client: create typed client
import { hc } from "hono/client"
import type { AppType } from "@/app/api/domain/[[...route]]/route"

const client = hc<AppType>("/")

// Type-safe calls
const res = await client.api.domain.$get({ query: { page: 1 } })
const data = await res.json()  // Fully typed response
```

### InferResponseType / InferRequestType

```typescript
import type { InferResponseType } from "hono/client"
import type { AppType } from "@/app/api/domain/[[...route]]/route"

type ResponseType = InferResponseType<AppType["api"]["domain"]["$get"]>
```

**Gotcha**: When using Hono route 404 fallbacks, use typed variables (not `satisfies`) to avoid `InferResponseType` producing `{}` union types.

## File Organization

```
app/api/
├── [domain]/
│   └── [[...route]]/
│       ├── route.ts        # Middleware + exports + type
│       ├── domain.ts       # Route handlers
│       └── utils.ts        # Helpers (optional)
```

The `[[...route]]` catch-all enables Hono to handle all sub-paths.

## Docs

- [Hono Docs](https://hono.dev/docs/)
- [Hono RPC](https://hono.dev/docs/guides/rpc)
- [Hono Zod Validator](https://hono.dev/docs/guides/validation#with-zod)
- [Hono Vercel Adapter](https://hono.dev/docs/getting-started/vercel)
- [@hono/clerk-auth](https://github.com/honojs/middleware/tree/main/packages/clerk-auth)
