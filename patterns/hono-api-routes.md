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

## Middleware Composition

Order matters. Apply middleware from outermost (CORS) to innermost (auth):

```typescript
import { Hono } from "hono"
import { handle } from "hono/vercel"
import { cors } from "hono/cors"
import { <authMiddleware> } from "<auth-provider>"

const app = new Hono().basePath("/api")

// 1. CORS — must be first (handles preflight OPTIONS)
app.use("*", cors({
  origin: (origin) => {
    if (!origin) return null
    if (origin === "https://<production-domain>" || origin.startsWith("http://localhost:")) {
      return origin
    }
    return null // Reject unknown origins for credentialed requests
  },
  credentials: true,
  allowMethods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
  allowHeaders: ["Authorization", "Content-Type"],
  maxAge: 86400,
}))

// 2. API key auth — check Bearer token before session auth
app.use("*", async (c, next) => {
  const authHeader = c.req.header("Authorization")
  if (authHeader?.startsWith("Bearer <key-prefix>_")) {
    const apiKey = authHeader.slice(7) // Remove "Bearer " prefix
    const result = await <verifyApiKey>(apiKey)
    if (result) {
      c.set("<api-key-user-id>", result.userId)
    }
  }
  await next()
})

// 3. Session auth — Clerk (or similar) for browser sessions
app.use("*", <authMiddleware>({
  secretKey: process.env.<AUTH_SECRET_KEY>,
  publishableKey: process.env.<AUTH_PUBLISHABLE_KEY>,
}))
```

### Dual Auth — getUserId Helper

Support both API key and session auth in route handlers:

```typescript
import { Context } from "hono"
import { getAuth } from "<auth-provider>"

export function getUserId(c: Context): string | null {
  // API key takes precedence (set by middleware)
  const apiKeyUserId = c.get("<api-key-user-id>") as string | undefined
  if (apiKeyUserId) return apiKeyUserId

  // Fall back to session auth
  const auth = getAuth(c)
  return auth?.userId ?? null
}

// Usage in route:
app.get("/<resource>", async (c) => {
  const userId = getUserId(c)
  if (!userId) return c.json({ error: "Unauthorized" }, 401)
  // ...
})
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
const [<result-a>, <result-b>, <result-c>] = await Promise.all([
  db.select().from(<table-a>).where(eq(<table-a>.orgId, orgId)),
  db.select({ count: count() }).from(<table-b>).where(eq(<table-b>.orgId, orgId)),
  db.select().from(<table-c>).where(eq(<table-c>.orgId, orgId)),
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

### Separate Hono Apps (Different Configs)

Split routes into separate Hono apps when they need different middleware or timeouts:

```typescript
// app/api/[[...route]]/route.ts — main API (long timeout for AI/streaming)
export const maxDuration = 300
const app = new Hono().basePath("/api")
// ... full middleware stack (CORS + API key + session auth)

// app/api/<domain>/[[...route]]/route.ts — <domain> routes (shorter timeout)
export const maxDuration = 30
const app = new Hono().basePath("/api/<domain>")
// ... lighter middleware stack (different auth, size limits)
```

## Docs

- [Hono Docs](https://hono.dev/docs/)
- [Hono RPC](https://hono.dev/docs/guides/rpc)
- [Hono Zod Validator](https://hono.dev/docs/guides/validation#with-zod)
- [Hono CORS Middleware](https://hono.dev/docs/middleware/builtin/cors)
- [Hono Vercel Adapter](https://hono.dev/docs/getting-started/vercel)
- [@hono/clerk-auth](https://github.com/honojs/middleware/tree/main/packages/clerk-auth)
