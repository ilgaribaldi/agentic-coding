# AGENTS.md

Agentic coding knowledge base — patterns, conventions, sub-agents, and skills for AI-assisted development.

## Structure

```
.agents/
├── REGISTRY.md              # Detailed index with technology lookup table
├── _templates/              # Copy-paste templates to add new content
│   ├── pattern.md           # Framework/convention pattern doc
│   ├── library.md           # Library/framework quick reference
│   └── agent.md             # Sub-agent definition
├── patterns/                # Patterns & conventions by domain
│   ├── README.md            # Patterns index
│   ├── typescript-stack.md  # TS monorepo, Bun, Turborepo, naming
│   ├── nextjs-patterns.md   # Next.js 15 App Router, layouts, middleware
│   ├── hono-api-routes.md   # Hono routes, Zod validation, RPC
│   ├── drizzle-schema.md    # Drizzle ORM, Neon, migrations
│   ├── tanstack-query.md    # TanStack Query v5 hooks, caching
│   ├── react-components.md  # Feature modules, state, forms, tables
│   ├── shadcn-ui.md         # Shadcn/UI, CVA, Tailwind theming
│   ├── monorepo-packages.md # Turborepo config, Bun workspaces
│   ├── authentication.md    # Clerk auth, middleware, product gating
│   ├── mobile-desktop.md    # Expo/React Native, Electron
│   ├── python-stack.md      # Flask, uv, deployment, CLI patterns
│   ├── python-patterns.md   # psycopg2, SQLAlchemy, retry, parallel
│   ├── data-science-patterns.md # xarray/Zarr, NumPy, joblib
│   └── documentation-links.md  # 40+ official doc URLs by category
├── agents/                  # Reusable sub-agent definitions
│   ├── debugger.md          # Bug investigation, root cause analysis
│   ├── doctor.md            # Audit docs against codebase
│   ├── explorer.md          # Codebase search and architecture
│   ├── security-audit.md    # OWASP Top 10 vulnerability assessment
│   └── react-expert.md     # React/Next.js performance (57 Vercel rules)
├── plans/                   # Implementation plans
│   ├── active/              # In-progress plans
│   └── archived/            # Completed/abandoned plans
└── skills/                  # Multi-step skill workflows
    ├── hyperscan/           # Deep codebase scan → context map
    ├── planning-with-files/ # File-based task planning
    ├── vercel-react-best-practices/  # 57 React perf rules (used by react-expert)
    └── agent-browser/           # Browser automation (testing, forms, screenshots)
```

## Plans

Plans go in `.agents/plans/`. Move to `archived/` when done.

```
plans/active/[task-name]/    # task_plan.md, findings.md, progress.md
plans/archived/[task-name]/  # Same structure, completed work
```

## Discovery

1. **Start here** — read this file for structure overview.
2. **Find specific content** — read [REGISTRY.md](.agents/REGISTRY.md) for the full index with technology lookup.
3. **Load relevant patterns** — read the specific `patterns/*.md` files for your task.
4. **Use sub-agents** — definitions in `agents/*.md` can be used as system prompts for specialized tasks.
5. **Use skills** — `skills/*/SKILL.md` define multi-step workflows.

## Adding Content

Templates in `_templates/` make it easy to add new content. Copy, fill in, and add an entry to `REGISTRY.md`.

```bash
# New pattern
cp .agents/_templates/pattern.md .agents/patterns/my-pattern.md

# New library reference
cp .agents/_templates/library.md .agents/patterns/my-library.md

# New agent
cp .agents/_templates/agent.md .agents/agents/my-agent.md
```

## Coverage

### TypeScript / Frontend
Next.js 15, Hono, Drizzle ORM, TanStack Query v5, React 19, Shadcn/UI, Tailwind CSS, Zod, Clerk, React Hook Form, Recharts, Turborepo, Bun

### Python / Backend
Flask, psycopg2, SQLAlchemy, xarray, Zarr, NumPy, SciPy, joblib, boto3, uv, pytest

### Cross-Platform
Expo SDK 55, React Native 0.83, Reanimated 4, Gesture Handler, Electron 35
