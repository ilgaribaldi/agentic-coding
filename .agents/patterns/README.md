# Code Preferences

General patterns, conventions, stack choices, and documentation references. These are **project-agnostic** guidelines for building apps — no project-specific details.

## Index

### Stack & Architecture

| Doc | Contents |
|-----|----------|
| [typescript-stack.md](typescript-stack.md) | TypeScript stack choices, versions, monorepo structure, build tooling |
| [python-stack.md](python-stack.md) | Python stack choices, package management (uv), deployment patterns |

### TypeScript Patterns

| Doc | Contents |
|-----|----------|
| [nextjs-patterns.md](nextjs-patterns.md) | Next.js App Router, layouts, route groups, middleware, server/client components |
| [hono-api-routes.md](hono-api-routes.md) | Hono route patterns, Zod validation, auth middleware, error handling, type-safe RPC |
| [drizzle-schema.md](drizzle-schema.md) | Drizzle ORM table definitions, relations, enums, indexes, migrations, Neon clients |
| [tanstack-query.md](tanstack-query.md) | React Query hooks, query keys, mutations, invalidation, caching strategies |
| [react-components.md](react-components.md) | Component patterns, state management (Zustand, URL, Context), forms, tables, charts |
| [shadcn-ui.md](shadcn-ui.md) | Shadcn component patterns, theming (CSS vars, dark mode), Tailwind preset |
| [monorepo-packages.md](monorepo-packages.md) | Turborepo, Bun workspaces, shared packages, import conventions, build pipeline |
| [mobile-desktop.md](mobile-desktop.md) | Expo Router, React Native patterns, Electron IPC, deep links, cross-platform |
| [authentication.md](authentication.md) | Clerk middleware, org-level auth, product gating, API route auth, session tokens |

### Python Patterns

| Doc | Contents |
|-----|----------|
| [python-patterns.md](python-patterns.md) | DB access (psycopg2), HTTP clients (retry/backoff), Flask services, batch inserts |
| [data-science-patterns.md](data-science-patterns.md) | xarray/zarr, S3 data loading, parallel processing (joblib), risk computation |

### Reference

| Doc | Contents |
|-----|----------|
| [documentation-links.md](documentation-links.md) | Official docs URLs for all libraries and frameworks |

## How to Use

Point your agent to this directory as static memory. Each file is self-contained with:
- **Patterns**: Code examples showing the canonical way to do things
- **Conventions**: Naming, file structure, import paths
- **Anti-patterns**: Things to avoid
- **Doc links**: Official references for deeper reading

Files are kept under 300 lines each. Prefer specific subpath imports (e.g., `@scope/constants/weather`) over barrel exports.
