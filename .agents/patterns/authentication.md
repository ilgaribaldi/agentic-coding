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
