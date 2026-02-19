# Registry

Master index for the agentic-coding knowledge base. Read this first to find relevant files.

## How This Works

```
REGISTRY.md          → You are here. Routing table for all content.
_templates/          → Copy-paste templates to add new docs.
patterns/            → Framework patterns, library usage, conventions.
agents/              → Reusable sub-agent definitions.
skills/              → Multi-step skill workflows.
```

**Adding content**: Copy a template from `_templates/`, fill it in, add an entry here.

---

## Code Patterns

Patterns, conventions, and best practices by domain.

### TypeScript / Frontend

| File | Covers | Key Topics |
|------|--------|------------|
| [typescript-stack.md](patterns/typescript-stack.md) | TypeScript monorepo foundations | Bun, Turborepo, naming conventions, strict mode |
| [nextjs-patterns.md](patterns/nextjs-patterns.md) | Next.js 15 App Router | Layouts, route groups, middleware, server/client components |
| [hono-api-routes.md](patterns/hono-api-routes.md) | Hono API routes | Two-file pattern, Zod validation, RPC, auth middleware |
| [drizzle-schema.md](patterns/drizzle-schema.md) | Drizzle ORM | Schema declaration, relations, Neon clients, migrations |
| [tanstack-query.md](patterns/tanstack-query.md) | TanStack Query v5 | Hooks, query keys, mutations, caching, invalidation |
| [react-components.md](patterns/react-components.md) | React component patterns | Feature modules, state management, forms, data tables |
| [shadcn-ui.md](patterns/shadcn-ui.md) | Shadcn/UI + Tailwind | CVA variants, theming, CSS variables, chart config |
| [monorepo-packages.md](patterns/monorepo-packages.md) | Monorepo packages | Turborepo config, Bun workspaces, internal packages |
| [authentication.md](patterns/authentication.md) | Auth (Clerk) | Middleware, org-level multi-tenancy, product gating |

### Python / Backend

| File | Covers | Key Topics |
|------|--------|------------|
| [python-stack.md](patterns/python-stack.md) | Python stack overview | Flask, uv, deployment, logging, CLI patterns |
| [python-patterns.md](patterns/python-patterns.md) | Python code patterns | psycopg2, SQLAlchemy, retry, parallel processing |
| [data-science-patterns.md](patterns/data-science-patterns.md) | Data science | xarray/Zarr, NumPy tensors, joblib, temporal ops |

### Cross-Platform

| File | Covers | Key Topics |
|------|--------|------------|
| [mobile-desktop.md](patterns/mobile-desktop.md) | Mobile + Desktop | Expo Router, React Native, Electron IPC |

### Reference

| File | Covers | Key Topics |
|------|--------|------------|
| [documentation-links.md](patterns/documentation-links.md) | Official doc URLs | 40+ technology links organized by category |

---

## Agents

Reusable sub-agent definitions for specialized tasks.

| File | Agent | Trigger |
|------|-------|---------|
| [debugger.md](agents/debugger.md) | Debugger | Bug reports, errors, unexpected behavior |
| [doctor.md](agents/doctor.md) | Doctor | Audit docs against codebase |
| [explorer.md](agents/explorer.md) | Explorer | "Where is X?", codebase search |
| [security-audit.md](agents/security-audit.md) | Security Audit | OWASP Top 10 vulnerability assessment |
| [react-expert.md](agents/react-expert.md) | React Expert | React/Next.js performance optimization, 57 Vercel rules |

---

## Skills

Multi-step workflows with templates and scripts.

| Skill | Purpose | Entry Point |
|-------|---------|-------------|
| [hyperscan](skills/hyperscan/SKILL.md) | Deep codebase scan → compact context map | `/hyperscan` |
| [planning-with-files](skills/planning-with-files/SKILL.md) | File-based task planning | `/planning-with-files` |
| [vercel-react-best-practices](skills/vercel-react-best-practices/SKILL.md) | 57 React/Next.js performance rules with BAD/GOOD examples | Used by react-expert agent |
| [agent-browser](skills/agent-browser/SKILL.md) | Browser automation for testing, form filling, screenshots, data extraction | `/agent-browser` |

---

## Quick Lookup by Technology

Find the right file for a given technology:

| Technology | Primary File | Also Mentioned In |
|-----------|-------------|-------------------|
| Next.js | nextjs-patterns.md | typescript-stack.md |
| Hono | hono-api-routes.md | — |
| Drizzle | drizzle-schema.md | — |
| TanStack Query | tanstack-query.md | react-components.md |
| React | react-components.md | shadcn-ui.md |
| Shadcn/UI | shadcn-ui.md | — |
| Tailwind CSS | shadcn-ui.md | — |
| Clerk | authentication.md | hono-api-routes.md |
| Expo / React Native | mobile-desktop.md | — |
| Electron | mobile-desktop.md | — |
| Turborepo | monorepo-packages.md | typescript-stack.md |
| Bun | monorepo-packages.md | typescript-stack.md |
| Flask | python-stack.md | python-patterns.md |
| psycopg2 | python-patterns.md | — |
| SQLAlchemy | python-patterns.md | — |
| xarray / Zarr | data-science-patterns.md | — |
| NumPy | data-science-patterns.md | — |
| joblib | data-science-patterns.md | — |
| uv | python-stack.md | — |
| Zod | hono-api-routes.md | tanstack-query.md |
| React Hook Form | react-components.md | — |
| Recharts | shadcn-ui.md | — |
