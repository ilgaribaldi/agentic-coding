# Agentic Coding

A portable knowledge base for AI-assisted software development. Drop it into any project to give your AI coding agent structured context — code patterns, reusable sub-agents, multi-step skills, and implementation plan tracking.

## What's Inside

```
agentic-coding/
├── AGENTS.md            # Master registry with technology lookup table
├── patterns/            # 17 code pattern docs across TS, Python, and cross-platform
├── templates/           # Templates for adding new content
└── .agents/
    ├── agents/          # 5 sub-agent definitions for specialized tasks
    ├── skills/          # 4 multi-step skill workflows
    └── skills/planning-with-files/plans/  # Implementation plans
```

### Patterns

Ready-to-use conventions for modern stacks. Each pattern doc includes stack choices, code examples, naming conventions, and anti-patterns.

| Domain | Patterns |
|--------|----------|
| **TypeScript / Frontend** | Next.js 15 App Router, Next.js project structure, Hono API routes, Drizzle ORM, TanStack Query v5, React 19 components, Shadcn/UI + Tailwind, Turborepo monorepos, Clerk auth, Vercel AI SDK, MCP server, Testing (Vitest/Playwright) |
| **Python / Backend** | Flask, psycopg2, SQLAlchemy, uv, deployment, CLI patterns, retry logic, parallel processing |
| **Data Science** | xarray/Zarr, NumPy, joblib, temporal operations |
| **Cross-Platform** | Expo SDK 55, React Native, Electron 35 |
| **Reference** | 40+ official documentation links by category |

### Agents

Sub-agent definitions that can be used as system prompts for specialized tasks:

| Agent | Purpose |
|-------|---------|
| **Debugger** | Bug investigation, root cause analysis, fix verification |
| **Doctor** | Audit documentation against actual codebase |
| **Explorer** | Codebase search, architecture understanding |
| **Security Audit** | OWASP Top 10 vulnerability assessment |
| **React Expert** | React/Next.js performance optimization (57 Vercel rules) |

### Skills

Multi-step workflows with templates and reference material:

| Skill | Purpose |
|-------|---------|
| **Hyperscan** | Deep codebase scan that produces a compact context map for implementation |
| **Planning with Files** | Manus-style file-based task planning with session recovery |
| **Vercel React Best Practices** | 57 performance rules with BAD/GOOD code examples |
| **Agent Browser** | Browser automation for testing, form filling, screenshots, and data extraction |

## Usage

### With Claude Code

Clone or copy into your project root. Point your `CLAUDE.md` at it:

```markdown
## Knowledge Base
Read `AGENTS.md` for the full registry and technology lookup.
```

### With Other AI Coding Tools

The pattern docs, agent definitions, and skill workflows are plain Markdown — they work with any AI tool that accepts context files. Load the relevant `patterns/*.md` files as context for your task.

## Adding Content

Templates make it easy to add new patterns, libraries, or agents:

```bash
# New pattern
cp templates/pattern.md patterns/my-pattern.md

# New library reference
cp templates/library.md patterns/my-library.md

# New agent
cp templates/agent.md .agents/agents/my-agent.md
```

After filling in the template, add an entry to `AGENTS.md`.

## Plans

Track implementation plans across sessions:

```
.agents/skills/planning-with-files/plans/{plan-slug}/    # task_plan.md, findings.md, progress.md
```

## License

MIT
