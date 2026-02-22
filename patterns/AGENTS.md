# Patterns

## File Index

### TypeScript / Frontend
- [typescript-stack.md](typescript-stack.md): TS monorepo foundations — Bun, Turborepo, naming, strict mode
- [nextjs-structure.md](nextjs-structure.md): Next.js project structure — full app tree, adding routes/features/pages, naming cheatsheet
- [nextjs-patterns.md](nextjs-patterns.md): Next.js 15 App Router — layouts, route groups, middleware, server/client
- [hono-api-routes.md](hono-api-routes.md): Hono API routes — two-file pattern, Zod validation, RPC, middleware composition, dual auth
- [drizzle-schema.md](drizzle-schema.md): Drizzle ORM — schema declaration, relations, Neon clients, CUID2, materialized paths
- [tanstack-query.md](tanstack-query.md): TanStack Query v5 — hooks, query keys, mutations, caching, invalidation
- [react-components.md](react-components.md): React component patterns — feature modules, state, forms, data tables
- [shadcn-ui.md](shadcn-ui.md): Shadcn/UI + Tailwind — CVA variants, theming, CSS variables, chart config
- [monorepo-packages.md](monorepo-packages.md): Monorepo packages — Turborepo config, Bun workspaces, internal packages
- [authentication.md](authentication.md): Auth (Clerk) — middleware, API key auth, scope-based authorization, multi-tenancy
- [ai-sdk-patterns.md](ai-sdk-patterns.md): Vercel AI SDK — streaming, tool calling, multi-model, structured output
- [testing-patterns.md](testing-patterns.md): Testing — Vitest config, mocking, Playwright E2E, component tests
- [mcp-patterns.md](mcp-patterns.md): MCP server — tool registration, Zod schemas, scope auth, structured responses

### Python / Backend
- [python-stack.md](python-stack.md): Python stack overview — Flask, uv, deployment, logging, CLI patterns
- [python-patterns.md](python-patterns.md): Python code patterns — psycopg2, SQLAlchemy, retry, parallel processing
- [data-science-patterns.md](data-science-patterns.md): Data science — xarray/Zarr, NumPy tensors, joblib, temporal ops

### Cross-Platform
- [mobile-desktop.md](mobile-desktop.md): Mobile + Desktop — Expo Router, React Native, Electron IPC

### Reference
- [documentation-links.md](documentation-links.md): Official doc URLs — 40+ technology links by category

### Upstream
- [AGENTS.md](../AGENTS.md): Master registry (root)

## Purpose
Code patterns, conventions, and best practices organized by domain. Each pattern doc includes stack choices, code examples, naming conventions, and anti-patterns.

## Workflow
1. Identify the technology or domain for your task.
2. Load the matching pattern file from the index above.
3. To add a new pattern: copy `templates/pattern.md`, fill it in, add entries here and in the root AGENTS.md.

## Do / Don't

| Do | Don't |
|----|-------|
| Load only the patterns relevant to your current task | Load all patterns at once (token waste) |
| Follow the conventions in the pattern doc | Override patterns without documenting why |
| Add new patterns via the template | Create pattern docs without registering them |
