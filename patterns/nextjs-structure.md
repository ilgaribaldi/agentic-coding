# Next.js Project Structure

Directory layout conventions for a Next.js + Hono + TanStack web app inside a Bun/Turborepo monorepo. This is the "where does it go?" reference — see cross-references at the bottom for code-level patterns.

## Full App Tree

```
apps/web/
├── src/
│   ├── app/                          # Next.js App Router (routes only)
│   │   ├── (platform)/              # Protected routes (sidebar layout)
│   │   │   ├── layout.tsx           # Client — sidebar + auth guards
│   │   │   ├── page.tsx             # Dashboard / home
│   │   │   ├── <feature>/
│   │   │   │   └── page.tsx         # Server component → renders client view
│   │   │   └── admin/
│   │   │       └── <section>/
│   │   │           └── page.tsx
│   │   ├── (auth)/                  # Auth pages (sign-in, sign-up)
│   │   ├── (docs)/                  # Public documentation pages
│   │   ├── api/                     # Hono API routes
│   │   │   ├── [[...route]]/        # Main API (catch-all)
│   │   │   │   ├── route.ts         # Middleware + handler exports
│   │   │   │   ├── <domain>.ts      # Route handlers per domain
│   │   │   │   └── ...
│   │   │   ├── <domain>/            # Separate Hono app (different middleware/timeout)
│   │   │   │   └── [[...route]]/
│   │   │   │       ├── route.ts
│   │   │   │       └── <domain>.ts
│   │   │   └── webhooks/            # Webhook endpoints
│   │   ├── <slug>/                  # Public dynamic routes
│   │   ├── layout.tsx               # Root layout — providers, fonts, metadata
│   │   ├── not-found.tsx
│   │   ├── globals.css
│   │   ├── manifest.ts
│   │   ├── robots.ts
│   │   └── sitemap.ts
│   ├── features/                    # Feature modules (domain-scoped)
│   │   └── <feature>/
│   │       ├── api/                 # TanStack Query hooks
│   │       ├── components/          # Feature-specific UI
│   │       ├── hooks/               # Custom hooks (non-API)
│   │       ├── views/               # Page-level client components
│   │       ├── utils/               # Pure helpers
│   │       ├── types.ts             # Feature-specific types
│   │       └── index.ts             # Public exports
│   ├── components/                  # Shared components (cross-feature)
│   │   ├── <component>.tsx          # Standalone shared components
│   │   ├── <domain>/                # Grouped shared components
│   │   │   └── <component>.tsx
│   │   ├── ui/                      # Base UI primitives (shadcn overrides)
│   │   └── providers.tsx            # React Query, theme, tooltip providers
│   ├── lib/                         # Shared utilities & infrastructure
│   │   ├── <domain>/                # Domain-specific logic (not feature-scoped)
│   │   ├── tools/                   # Agent tool definitions
│   │   ├── hooks/                   # Shared hooks (not feature-specific)
│   │   ├── prompts/                 # AI prompt templates
│   │   └── utils.ts                 # General helpers (cn, formatters)
│   ├── db/                          # Database access layer
│   │   ├── drizzle.ts               # Drizzle client instance
│   │   ├── schema.ts                # Schema imports + re-exports
│   │   ├── pool.ts                  # Connection pool config
│   │   └── migrations/              # Drizzle migration files
│   ├── config/                      # App-level configuration
│   ├── contexts/                    # React contexts
│   ├── stores/                      # Zustand stores
│   ├── middleware.ts                # Next.js middleware (auth, redirects)
│   └── types.ts                     # Global type declarations
├── __tests__/                       # Test files (mirrors src/ structure)
├── scripts/                         # One-off scripts (backfills, seeds)
├── public/                          # Static assets
├── next.config.mjs
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Adding an API Route

### Step 1: Choose where it lives

| Scenario | Location |
|----------|----------|
| Shares middleware/auth with main API | `app/api/[[...route]]/<domain>.ts` |
| Needs different timeout, auth, or body limits | `app/api/<domain>/[[...route]]/route.ts` + `<domain>.ts` |
| Webhook (no session auth) | `app/api/webhooks/<provider>/route.ts` |

### Step 2: Create the handler file

```typescript
// app/api/[[...route]]/<domain>.ts
import { Hono } from "hono"

const app = new Hono()
  .get("/", async (c) => { /* ... */ })
  .post("/", async (c) => { /* ... */ })

export default app
```

### Step 3: Mount in route.ts

```typescript
// app/api/[[...route]]/route.ts
import <domain> from "./<domain>"

const routes = app
  .route("/<domain>", <domain>)
  // ... existing routes
```

### Step 4: When to split into a separate Hono app

Create a separate `app/api/<domain>/[[...route]]/` when:
- The domain needs a **different `maxDuration`** (e.g., file uploads vs AI streaming)
- It requires **different middleware** (e.g., no session auth, different CORS)
- It needs **different body size limits**

Each separate Hono app gets its own `route.ts` with its own middleware stack and `export const maxDuration`.

## Adding a Feature

### Step 1: Create the feature directory

```
src/features/<feature>/
├── api/                    # TanStack Query hooks
│   ├── index.ts            # Re-exports all hooks
│   ├── use-get-<resource>.ts
│   ├── use-create-<resource>.ts
│   ├── use-update-<resource>.ts
│   └── use-delete-<resource>.ts
├── components/             # Feature-specific UI components
│   ├── index.ts            # Re-exports
│   ├── <resource>-list.tsx
│   ├── <resource>-card.tsx
│   └── <resource>-form.tsx
├── hooks/                  # Non-API hooks (local state, behaviors)
│   └── use-<behavior>.ts
├── views/                  # Page-level client components
│   └── <feature>-client.tsx
├── utils/                  # Pure helper functions
│   └── <helpers>.ts
├── types.ts                # Feature-specific types (optional)
└── index.ts                # Public API barrel export
```

### What goes where

| Subdir | Contains | Example |
|--------|----------|---------|
| `api/` | TanStack Query hooks that call Hono endpoints | `use-get-comments.ts` |
| `components/` | UI components only used within this feature | `comment-item.tsx` |
| `hooks/` | Custom hooks for local behavior (not data fetching) | `use-comment-editor.ts` |
| `views/` | Top-level client components rendered by `page.tsx` | `community-client.tsx` |
| `utils/` | Pure functions, formatters, transformers | `highlight-match.tsx` |

### Step 2: Create the page

```typescript
// app/(platform)/<feature>/page.tsx  (server component)
import { FeatureClient } from "@/features/<feature>/views/<feature>-client"

export default function FeaturePage() {
  return <FeatureClient />
}
```

### Step 3: Wire up API hooks

Feature API hooks live in `features/<feature>/api/` and call the Hono endpoints mounted in `app/api/`.

## Adding a Page

1. **Create the route**: `app/(platform)/<feature>/page.tsx` (server component)
2. **Create the view**: `src/features/<feature>/views/<feature>-client.tsx` (client component)
3. **Page exports the view**: The server component just renders the client view

```typescript
// app/(platform)/settings/page.tsx
import { SettingsClient } from "@/features/settings/views/settings-client"
export default function SettingsPage() {
  return <SettingsClient />
}
```

For **nested routes**, create subdirectories:

```
app/(platform)/<feature>/
├── page.tsx                  # /feature
├── [id]/
│   └── page.tsx              # /feature/:id
└── new/
    └── page.tsx              # /feature/new
```

## Shared vs Feature-Scoped

| Goes in `src/components/` (shared) | Goes in `src/features/<feature>/components/` (scoped) |
|-------------------------------------|-------------------------------------------------------|
| Used by 2+ features | Used by only one feature |
| App shell (sidebar, header, footer) | Feature-specific cards, lists, forms |
| Generic UI (modals, dialogs, toasts) | Domain-specific UI (vote buttons, comment threads) |
| Editor components | Feature-specific editor extensions |
| Provider wrappers | — |

**Rule of thumb**: Start scoped. Move to shared when a second feature needs it.

## Package Internal Structure

```
packages/<pkg>/
├── src/
│   ├── index.ts             # Main barrel export
│   ├── <submodule>/         # Grouped by domain
│   │   ├── index.ts         # Submodule exports
│   │   └── <file>.ts
│   └── <file>.ts            # Top-level module files
├── package.json             # exports map defines public API
└── tsconfig.json            # Extends shared config
```

Package `exports` in `package.json` define the public API surface:

```json
{
  "exports": {
    ".": "./src/index.ts",
    "./<submodule>": "./src/<submodule>/index.ts",
    "./<submodule>/*": "./src/<submodule>/*.ts"
  }
}
```

Import via subpath, not barrel:

```typescript
// Good
import { Button } from "@scope/ui/button"
import { formatDate } from "@scope/core/dates"

// Avoid
import { Button } from "@scope/ui"
```

## Naming Cheatsheet

| Type | Convention | Example |
|------|-----------|---------|
| **Route group** | `(purpose)` | `(platform)`, `(auth)`, `(docs)` |
| **Catch-all route** | `[[...route]]` | `app/api/[[...route]]/` |
| **Dynamic segment** | `[param]` | `app/(platform)/[id]/page.tsx` |
| **Page file** | `page.tsx` | Always `page.tsx` in route dir |
| **Layout file** | `layout.tsx` | Always `layout.tsx` in route dir |
| **API handler** | `<domain>.ts` | `community.ts`, `files.ts` |
| **Feature dir** | `kebab-case` | `src/features/community/` |
| **Component file** | `kebab-case.tsx` | `comment-item.tsx` |
| **Hook file** | `use-<name>.ts` | `use-get-comments.ts` |
| **View file** | `<feature>-client.tsx` | `community-client.tsx` |
| **Barrel export** | `index.ts` | One per feature subdir |
| **Store file** | `use-<name>.ts` in `stores/` | `stores/use-editor-store.ts` |
| **Context file** | `<name>-context.tsx` | `contexts/workspace-context.tsx` |
| **Type file** | `types.ts` | Per feature or global |
| **Util file** | `<descriptive>.ts` | `highlight-match.tsx`, `url.ts` |
| **Script file** | `<verb>-<noun>.ts` in `scripts/` | `backfill-embeddings.ts` |
| **Test file** | `<source>.test.ts` in `__tests__/` | `__tests__/lib/utils.test.ts` |

## Cross-References

| Topic | File | What it covers |
|-------|------|----------------|
| App Router patterns | [nextjs-patterns.md](nextjs-patterns.md) | Layouts, middleware, server/client, security headers |
| Hono API routes | [hono-api-routes.md](hono-api-routes.md) | Two-file pattern, Zod validation, RPC, middleware, dual auth |
| React components | [react-components.md](react-components.md) | Feature modules, state management, forms, data tables |
| TanStack Query | [tanstack-query.md](tanstack-query.md) | Query hooks, keys, mutations, caching |
| Monorepo packages | [monorepo-packages.md](monorepo-packages.md) | Turborepo, Bun workspaces, package exports, import boundaries |
| Authentication | [authentication.md](authentication.md) | Clerk middleware, API keys, scopes |
| Shadcn/UI | [shadcn-ui.md](shadcn-ui.md) | CVA variants, theming, CSS variables |
