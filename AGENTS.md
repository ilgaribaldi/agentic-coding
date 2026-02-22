# Agentic Coding

Portable agentic coding knowledge base — patterns, conventions, sub-agents, and skills for AI-assisted development.

## File Index

### Core
- [AGENTS.md](AGENTS.md): Master registry (this file)
- [README.md](README.md): Human-readable overview and usage guide

### Patterns — TypeScript / Frontend
- [typescript-stack.md](patterns/typescript-stack.md): TS monorepo foundations — Bun, Turborepo, naming, strict mode
- [nextjs-structure.md](patterns/nextjs-structure.md): Next.js project structure — full app tree, adding routes/features/pages, naming cheatsheet
- [nextjs-patterns.md](patterns/nextjs-patterns.md): Next.js 15 App Router — layouts, route groups, middleware, server/client
- [hono-api-routes.md](patterns/hono-api-routes.md): Hono API routes — two-file pattern, Zod validation, RPC, middleware composition, dual auth
- [drizzle-schema.md](patterns/drizzle-schema.md): Drizzle ORM — schema declaration, relations, Neon clients, CUID2, materialized paths
- [tanstack-query.md](patterns/tanstack-query.md): TanStack Query v5 — hooks, query keys, mutations, caching, invalidation
- [react-components.md](patterns/react-components.md): React component patterns — feature modules, state, forms, data tables
- [shadcn-ui.md](patterns/shadcn-ui.md): Shadcn/UI + Tailwind — CVA variants, theming, CSS variables, chart config
- [monorepo-packages.md](patterns/monorepo-packages.md): Monorepo packages — Turborepo config, Bun workspaces, internal packages
- [authentication.md](patterns/authentication.md): Auth (Clerk) — middleware, API key auth, scope-based authorization, multi-tenancy
- [ai-sdk-patterns.md](patterns/ai-sdk-patterns.md): Vercel AI SDK — streaming, tool calling, multi-model, structured output
- [testing-patterns.md](patterns/testing-patterns.md): Testing — Vitest config, mocking, Playwright E2E, component tests
- [mcp-patterns.md](patterns/mcp-patterns.md): MCP server — tool registration, Zod schemas, scope auth, structured responses

### Patterns — Python / Backend
- [python-stack.md](patterns/python-stack.md): Python stack overview — Flask, uv, deployment, logging, CLI patterns
- [python-patterns.md](patterns/python-patterns.md): Python code patterns — psycopg2, SQLAlchemy, retry, parallel processing
- [data-science-patterns.md](patterns/data-science-patterns.md): Data science — xarray/Zarr, NumPy tensors, joblib, temporal ops

### Patterns — Cross-Platform
- [mobile-desktop.md](patterns/mobile-desktop.md): Mobile + Desktop — Expo Router, React Native, Electron IPC

### Patterns — Reference
- [documentation-links.md](patterns/documentation-links.md): Official doc URLs — 40+ technology links organized by category

### Agents
- [debugger.md](.agents/agents/debugger.md): Bug investigation, root cause analysis, fix verification
- [doctor.md](.agents/agents/doctor.md): Audit documentation against actual codebase
- [explorer.md](.agents/agents/explorer.md): Codebase search, architecture understanding
- [security-audit.md](.agents/agents/security-audit.md): OWASP Top 10 vulnerability assessment
- [react-expert.md](.agents/agents/react-expert.md): React/Next.js performance optimization (57 Vercel rules)

### Skills
- [SKILL.md](.agents/skills/hyperscan/SKILL.md): Hyperscan — deep codebase scan, compact context map
- [SKILL.md](.agents/skills/planning-with-files/SKILL.md): Planning with Files — file-based task planning with session recovery
- [SKILL.md](.agents/skills/vercel-react-best-practices/SKILL.md): Vercel React Best Practices — 57 perf rules with BAD/GOOD examples
- [SKILL.md](.agents/skills/agent-browser/SKILL.md): Agent Browser — browser automation for testing, forms, screenshots

### Templates
- [pattern.md](templates/pattern.md): Template for new framework/convention patterns
- [library.md](templates/library.md): Template for new library/framework quick references
- [agent.md](templates/agent.md): Template for new sub-agent definitions

### Plans
- [plans/](.agents/skills/planning-with-files/plans): Implementation plans cataloged within planning-with-files skill

## Workflow
1. Read this file for the full registry and technology lookup.
2. Load relevant `patterns/*.md` files for your task.
3. Use `.agents/agents/*.md` definitions for specialized sub-agent prompts.
4. Use `.agents/skills/*/SKILL.md` for multi-step workflows.
5. To add content: copy a template from `templates/`, fill it in, add an entry here.

## Quick Lookup by Technology

| Technology | Primary File | Also In |
|-----------|-------------|---------|
| Next.js | nextjs-patterns.md | nextjs-structure.md, typescript-stack.md |
| Next.js structure | nextjs-structure.md | nextjs-patterns.md, react-components.md |
| Hono | hono-api-routes.md | nextjs-structure.md |
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
| Zod | hono-api-routes.md | tanstack-query.md, ai-sdk-patterns.md, mcp-patterns.md |
| React Hook Form | react-components.md | — |
| Recharts | shadcn-ui.md | — |
| Vercel AI SDK | ai-sdk-patterns.md | — |
| OpenAI / Anthropic / Google | ai-sdk-patterns.md | — |
| MCP (Model Context Protocol) | mcp-patterns.md | — |
| Vitest | testing-patterns.md | — |
| Playwright | testing-patterns.md | — |
| Testing Library | testing-patterns.md | — |
| CUID2 | drizzle-schema.md | — |
| dnd-kit | documentation-links.md | — |

## Do / Don't

| Do | Don't |
|----|-------|
| Register every new file here | Add content without an index entry |
| Use templates from `templates/` | Create docs from scratch |
| Keep entries in `[filename](path): description` format | Use verbose prose in the index |
| Use relative paths (repo is portable) | Hardcode machine-specific absolute paths |
