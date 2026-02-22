# Authentication (Clerk)

## Overview

Clerk provides auth with organization-level multi-tenancy and product gating.

## Middleware (Route Protection)

```typescript
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server"

const publicRoutes = createRouteMatcher(["/sign-in(.*)", "/sign-up(.*)"])
const adminRoutes = createRouteMatcher(["/admin(.*)"])
const productRoutes = {
  analytics: createRouteMatcher(["/analytics(.*)"]),
  reports: createRouteMatcher(["/reports(.*)"]),
  dashboard: createRouteMatcher(["/dashboard(.*)"]),
}

export default clerkMiddleware(async (auth, req) => {
  // Root redirect
  if (req.nextUrl.pathname === "/") {
    const userId = (await auth()).userId
    return NextResponse.redirect(new URL(userId ? "/dashboard" : "/sign-in", req.url))
  }

  // Skip auth for public routes
  if (publicRoutes(req)) return

  // Admin check
  if (adminRoutes(req)) {
    const { orgSlug } = await auth()
    if (orgSlug !== "admin") return redirect("/invalid-account")
  }

  // Org membership required for platform routes
  const { orgSlug, orgId } = await auth()
  if (!orgSlug) return redirect("/onboarding")

  // Product gating via DB
  if (productRoutes.analytics(req)) {
    const hasAccess = await hasActiveProduct(orgId!, "Analytics")
    if (!hasAccess) return redirect("/access-denied")
  }
})
```

## API Route Auth

Every Hono route checks auth:

```typescript
import { getAuth } from "@hono/clerk-auth"

app.get("/", async (c) => {
  const auth = getAuth(c)
  if (!auth?.userId || !auth?.orgId) {
    return c.json({ error: "Unauthorized" }, 401)
  }
  // auth.orgId is the current organization
  // auth.userId is the current user
})
```

## Product Gating

Organizations are gated by product access in the DB:

```typescript
async function hasActiveProduct(orgId: string, productName: string): Promise<boolean> {
  const result = await db.select({ id: organizationProducts.id })
    .from(organizationProducts)
    .innerJoin(products, and(
      eq(products.id, organizationProducts.productId),
      eq(products.name, productName),
    ))
    .where(and(
      eq(organizationProducts.organizationId, orgId),
      eq(organizationProducts.active, true),
    ))
    .limit(1)
  return result.length > 0
}
```

## Client-Side Auth

```typescript
// React hooks
import { useAuth, useUser, useOrganization } from "@clerk/nextjs"

const { userId, orgId, getToken } = useAuth()
const { user } = useUser()
const { organization } = useOrganization()
```

## Org Change Cache Invalidation

When user switches organization, clear all cached data:

```typescript
export function useInvalidateOnOrgChange() {
  const { organization } = useOrganization()
  const queryClient = useQueryClient()
  const prevOrgIdRef = useRef<string | null>(null)

  useEffect(() => {
    const orgId = organization?.id ?? null
    if (prevOrgIdRef.current === null) {
      prevOrgIdRef.current = orgId
      return
    }
    if (prevOrgIdRef.current !== orgId) {
      queryClient.cancelQueries({ queryKey: ["domain"] })
      queryClient.removeQueries({ queryKey: ["domain"] })
      prevOrgIdRef.current = orgId
    }
  }, [organization?.id, queryClient])
}
```

## API Key Authentication

Support programmatic access alongside session auth (for CLIs, agents, external integrations):

### Key Format & Storage

```typescript
import { createHash, randomBytes } from "crypto"

// Generate: prefix + random bytes
// Use a short prefix to identify key type (e.g., sk_ for secret, pk_ for public)
function generateApiKey(prefix = "<prefix>"): { raw: string; hash: string } {
  const raw = `${prefix}_${randomBytes(16).toString("hex")}` // "<prefix>_abc123..."
  const hash = createHash("sha256").update(raw).digest("hex")
  return { raw, hash }
}

// Store the HASH in DB, show the RAW key to user ONCE
const { raw, hash } = generateApiKey()
await db.insert(<api-keys-table>).values({
  userId,
  keyHash: hash,
  name: "<key-name>",
  scopes: JSON.stringify(["<resource-a>:read", "<resource-a>:write"]),
  expiresAt: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000), // 90 days
})
// Return `raw` to user — never stored, never retrievable
```

### Verification Middleware

```typescript
const API_KEY_PREFIX = "<prefix>_" // Match your generateApiKey prefix

app.use("*", async (c, next) => {
  const authHeader = c.req.header("Authorization")
  if (authHeader?.startsWith(`Bearer ${API_KEY_PREFIX}`)) {
    const apiKey = authHeader.slice(7) // Remove "Bearer " prefix
    const result = await <verifyApiKey>(apiKey)
    if (result) {
      c.set("<api-key-user-id>", result.userId)
      c.set("<api-key-scopes>", result.scopes)
    }
  }
  await next()
})
```

## Scope-Based Authorization

Fine-grained permissions using `resource:action` naming (like GitHub PATs):

### Scope Definitions

```typescript
export const SCOPES = {
  <RESOURCE_A>_READ: "<resource-a>:read",
  <RESOURCE_A>_WRITE: "<resource-a>:write",
  <RESOURCE_A>_DELETE: "<resource-a>:delete",
  <RESOURCE_B>_READ: "<resource-b>:read",
  <RESOURCE_B>_WRITE: "<resource-b>:write",
  // ... add per resource
} as const

export type Scope = (typeof SCOPES)[keyof typeof SCOPES]
```

### Scope Checking

```typescript
export function hasScope(context: { scopes: string[] }, required: string): boolean {
  return context.scopes.includes(required)
}

export function hasAllScopes(context: { scopes: string[] }, required: string[]): boolean {
  return required.every(s => context.scopes.includes(s))
}

// Usage in route handler:
app.post("/<resource>", async (c) => {
  const scopes = c.get("<api-key-scopes>")
  if (scopes && !hasScope({ scopes }, SCOPES.<RESOURCE_A>_WRITE)) {
    return c.json({ error: "Insufficient scope: <resource-a>:write required" }, 403)
  }
  // ...
})
```

### Scope Presets (for UI)

```typescript
export const SCOPE_PRESETS = {
  READ_ONLY: [SCOPES.<RESOURCE_A>_READ],
  READ_WRITE: [SCOPES.<RESOURCE_A>_READ, SCOPES.<RESOURCE_A>_WRITE],
  FULL_ACCESS: Object.values(SCOPES),
} as const
```

### Tool-to-Scope Mapping

Map operation names to required scopes for dynamic authorization:

```typescript
const TOOL_SCOPES: Record<string, Scope> = {
  <action_a>: SCOPES.<RESOURCE_A>_READ,
  <action_b>: SCOPES.<RESOURCE_A>_WRITE,
  <action_c>: SCOPES.<RESOURCE_A>_DELETE,
  <action_d>: SCOPES.<RESOURCE_B>_WRITE,
}

function authorizeToolCall(toolName: string, scopes: string[]): boolean {
  const required = TOOL_SCOPES[toolName]
  if (!required) return false // Unknown tool
  return scopes.includes(required)
}
```

## Provider Setup

```typescript
// Root layout
<ClerkProvider>
  <html><body>{children}</body></html>
</ClerkProvider>

// Hono middleware (route.ts)
app.use("*", clerkMiddleware({
  secretKey: process.env.CLERK_SECRET_KEY,
  publishableKey: process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
}))
```

## Docs

- [Clerk Next.js](https://clerk.com/docs/reference/nextjs/overview)
- [clerkMiddleware](https://clerk.com/docs/reference/nextjs/clerk-middleware)
- [useAuth](https://clerk.com/docs/nextjs/reference/hooks/use-auth)
- [Organizations](https://clerk.com/docs/guides/organizations/overview)
- [Roles & Permissions](https://clerk.com/docs/guides/organizations/control-access/roles-and-permissions)
- [Webhooks](https://clerk.com/docs/guides/development/webhooks/syncing)
