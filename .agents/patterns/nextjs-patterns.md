# Next.js Patterns

## App Router Structure

```
app/
├── (platform)/        # Protected dashboard routes (sidebar layout)
│   ├── layout.tsx     # Client — sidebar + org-change invalidation
│   └── [feature]/
│       └── page.tsx   # Server component → renders client view
├── (auth)/            # Auth pages (sign-in, sign-up)
├── (public)/          # Public pages (access-denied, landing)
├── api/               # Hono API routes (see hono-api-routes.md)
├── layout.tsx         # Root layout — providers, fonts, metadata
└── middleware.ts      # Clerk auth + route protection
```

## Root Layout Pattern

```typescript
import { ClerkProvider } from "@clerk/nextjs"
import { ThemeProvider } from "@/components/theme-provider"
import { Toaster } from "@scope/ui/sonner"

export const metadata: Metadata = {
  title: { default: "App Name", template: "%s | App Name" },
  description: "...",
}

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <ClerkProvider>
      <html><body>
        <ThemeProvider>
          <Providers>       {/* React Query provider */}
            <TooltipProvider>
              {children}
              <Toaster />
            </TooltipProvider>
          </Providers>
        </ThemeProvider>
      </body></html>
    </ClerkProvider>
  )
}
```

## Route Group Layout

```typescript
"use client"
import { SidebarLayout } from "@/components/sidebar"
import { useInvalidateOnOrgChange } from "@/features/<domain>/api/use-invalidate-on-org-change"

export default function DashboardLayout({ children }: { children: React.ReactNode }) {
  useInvalidateOnOrgChange() // Clear cache on org switch
  return (
    <SidebarLayout>
      <div className="flex h-full flex-col dark:text-white">{children}</div>
    </SidebarLayout>
  )
}
```

## Page Pattern

Server component that renders a client view:

```typescript
// app/(platform)/feature/page.tsx
export default function FeaturePage() {
  return <FeatureClient />
}
```

## Server vs Client Components

- **Server by default** — pages, layouts are server components
- Mark with `"use client"` only when needed (hooks, event handlers, browser APIs)
- Keep data fetching in hooks (TanStack Query) inside client components
- Server components for static rendering, metadata, initial layout

## Middleware (Auth + Route Protection)

```typescript
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server"

const adminMatcher = createRouteMatcher(["/admin(.*)"])
const protectedMatcher = createRouteMatcher(["/dashboard(.*)", "/<feature>(.*)"])

export default clerkMiddleware(async (auth, req) => {
  if (req.nextUrl.pathname === "/") {
    const userId = (await auth()).userId
    return NextResponse.redirect(new URL(userId ? "/dashboard" : "/sign-in", req.url))
  }

  if (protectedMatcher(req)) {
    const { orgSlug, orgId } = await auth()
    if (!orgSlug) return NextResponse.redirect(new URL("/onboarding", req.url))
    // Product gating via DB query
  }
})
```

## Security Headers

```javascript
// next.config.mjs
headers: [
  { key: "X-Frame-Options", value: "DENY" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(self)" },
]
```

## Performance

- `experimental.optimizePackageImports` for lucide-react, recharts, date-fns
- `next dev --turbopack` for fast HMR
- Dynamic imports for heavy components (maps, charts, XLSX)

```typescript
const MapComponent = dynamic(() => import("./map"), {
  ssr: false,
  loading: () => <MapSkeleton />,
})
```

## Docs

- [App Router](https://nextjs.org/docs/app)
- [Route Groups](https://nextjs.org/docs/app/building-your-application/routing/route-groups)
- [Middleware](https://nextjs.org/docs/app/building-your-application/routing/middleware)
- [Server Components](https://nextjs.org/docs/app/building-your-application/rendering/server-components)
- [Dynamic Imports](https://nextjs.org/docs/app/building-your-application/optimizing/lazy-loading)
