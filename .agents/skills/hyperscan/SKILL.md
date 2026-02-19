---
name: hyperscan
description: "Deep, exhaustive codebase scan that maps every relevant file, component, route, schema, test, command, and cross-repo interaction for a given task. Produces a compact, token-efficient context map ready for implementation. Use when starting complex tasks, before planning, or when you need complete understanding of how a feature area works across the multi-repo workspace. Trigger: /hyperscan followed by a task description."
---

# Hyperscan

Exhaustive codebase scan. Produces a compact context map: signatures + relationships + data flow — enough to implement without further discovery. Optimized for LLM comprehension based on context retrieval research.

## Workflow

### Phase 0: Scope

Extract task from user message. Determine:
- Which repos are involved (check project docs for workspace structure and cross-repo docs index)
- Which feature areas, API routes, DB tables, packages are relevant
- Single-repo or cross-repo

Check for existing scans first: `Glob: .claude/skills/hyperscan/scans/*.md`. If a recent scan covers the same area, load it and do a delta — don't rescan from scratch.

### Phase 1: Triage (fast, parallel reads)

Read the minimum docs to orient. Use any routing table or context-loader doc available in `.claude/agents/`. Read in parallel:
- Relevant cross-repo doc(s) from `.claude/docs/cross-repo/`
- Relevant repo doc(s) from `.claude/docs/repos/`
- CLAUDE.md of any repo being modified
- Existing plans: `Glob: .claude/plans/active/**/task_plan.md`

After triage, estimate file count. This determines Phase 2 strategy:
- **Under 20 files**: Scan directly — no agents needed. Read files yourself.
- **20-50 files**: Spawn 2-3 focused Explore agents in parallel.
- **50+ files or 3+ repos**: Spawn 3-5 Explore agents in parallel.

### Phase 2: Deep Scan

Whether scanning directly or via agents, the goal is the same: for every relevant file, capture its **signature** (exports, function signatures, type shapes) and **relationships** (what it imports, calls, renders, queries). Do NOT read full function bodies — signatures + relationships = 90% of what's needed at 10% of the tokens.

**Agent strategy** (when spawning): Send agents in a single message. Each gets a focused mission and outputs findings using semantic names (see Output Format). Adapt to the task:

For a **web feature** task:
1. **Feature+Hooks agent**: feature components, hooks, utils — map exports, props, hook signatures
2. **API+Schema agent**: routes, DB schema, Zod schemas — map endpoints, table shapes, validations
3. **Packages+Tests agent**: shared package files imported by the feature, test files

For a **cross-repo** task:
1. **TS agent**: feature components, API routes, hooks, types
2. **Python agent**: controllers, services, models, SDK methods
3. **Integration agent**: trace HTTP calls between repos, env vars, URL construction

For scan patterns, consult `references/scan-patterns.md` within this skill.

### Phase 3: Synthesize

Merge findings into the output format below. Write to:
```
.claude/skills/hyperscan/scans/YYYY-MM-DD-[task-slug].md
```
Use today's date + kebab-case slug (e.g., `2024-01-15-implement-user-dashboard.md`).

Relevance filter: cap at ~40 files. If more were discovered, rank by relevance to the task (files that will be modified > files that are called > files that are tangentially related). Cut the tail.

### Phase 4: Present

Show user a brief summary:
- Repos involved + role
- File count mapped
- Key architectural insight or gotcha
- Path to full scan file
- Suggested next step

## Output Format

Research-backed structure: highest-value info at top (primacy effect), gotchas at bottom (recency effect), file maps in middle. Use **semantic names** as references — function names, component names, endpoint paths — not arbitrary IDs. These are self-describing and match what you'll type when editing code.

### Formatting Rules

- **Semantic references**: Use export/component/endpoint names as identifiers. `OrderTimeline`, `useOrders()`, `GET /api/orders`, `orders table`. Never arbitrary IDs.
- **Full path on first mention**: `features/orders/components/timeline.tsx:12`. Semantic name thereafter: `OrderTimeline`.
- **Inline connections**: `OrderTimeline — uses useOrders(), renders Order[]`. No separate lookup table.
- **Type shapes inline at point-of-use**: `useOrders() → { orders: Order[], total: number }`. Only break out a separate Types section for complex shared types used 3+ places.
- **No prose**: Tables, lists, code blocks only.
- **Signatures not bodies**: Export names, function signatures with param types, return types. Not implementations.
- **Abbreviate**: `FK` not "foreign key", `→` not "calls", `?` for optional. Reader is an LLM.

### Template

````markdown
# Hyperscan: [task summary]
Date: YYYY-MM-DD | Repos: N | Files: N

## Data Flow
The most critical section — goes first for primacy.
```
User action → OrderTimeline (timeline.tsx:12)
  → useOrders(orgId) (use-orders.ts:5)
    → GET /api/orders (route.ts:45)
      → SELECT orders WHERE org_id = ? (orders table)
      → returns { orders: Order[], total: number }
  → renders Order[] as timeline cards
```
Cross-repo (if applicable):
```
GET /api/orders (route.ts:45)
  → HTTP GET → payment-service /orders/sync (orders_controller.py:15)
    → order_service.sync_orders() (order_service.py:30)
      → SDK client.get_orders() → DB
```

## Critical Entities
Top 3-5 items the implementer must understand. Anchors for everything below.
- `OrderTimeline` — `features/orders/components/timeline.tsx:12` — main view component, renders order cards
- `useOrders(orgId)` — `packages/api/src/hooks/orders.ts:30` — React Query hook, query key `["orders", orgId]`
- `GET /api/orders` — `app/api/orders/[[...route]]/route.ts:45` — Hono route, queries orders table, returns `{ orders, total }`
- `orders` table — `packages/db/src/schema/orders.ts:12` — `{ id, status, amount, createdAt, customerId FK→customers }`

## File Map
### Feature: orders
| File | Exports | Connections |
|------|---------|-------------|
| `features/orders/components/timeline.tsx:12` | `OrderTimeline` | uses useOrders(), renders Order[] |
| `features/orders/components/order-card.tsx:1` | `OrderCard` | props: Order, used by OrderTimeline |
| `features/orders/hooks/use-orders.ts:5` | `useOrders(orgId)` | calls GET /api/orders → `{ orders: Order[], total }` |
| `features/orders/utils/format-order.ts:1` | `formatOrderDate()`, `statusColor()` | pure utils, used by OrderCard |

### API Routes
| File | Method + Path | Schema/Validation | Returns |
|------|--------------|-------------------|---------|
| `app/api/orders/[[...route]]/route.ts:45` | GET /api/orders | `ordersQuerySchema: { orgId, status?, amount? }` | `{ orders: Order[], total }` |

### DB Schema
| File | Table | Key columns | Relations |
|------|-------|-------------|-----------|
| `packages/db/src/schema/orders.ts:12` | `orders` | `id, status, amount, createdAt, customerId` | FK→customers, FK→organizations |

### Shared Packages
| File | Exports | Used by |
|------|---------|---------|
| `packages/api/src/hooks/orders.ts:30` | `useOrders()`, `useOrdersMutation()` | OrderTimeline, mobile OrdersScreen |
| `packages/constants/src/orders/index.ts:1` | `ORDER_STATUSES`, `PAYMENT_METHODS` | OrderCard, order-card.tsx, route.ts |

### Python (if cross-repo)
| File | What | Signature | Connections |
|------|------|-----------|-------------|
| `payment-service/.../orders_controller.py:15` | `/orders/sync` endpoint | `GET ?org_id=&status=` → `{ orders: [...] }` | calls order_service.sync_orders() |
| `payment-service/.../order_service.py:30` | Sync logic | `sync_orders(org_id, status) → list[Order]` | queries DB, calls SDK |

## Shared Types
Only for complex types used in 3+ places. Simple return shapes go inline above.
| Name | Defined at | Shape | Used by |
|------|-----------|-------|---------|
| `Order` | `packages/db/src/schema/orders.ts:5` | `{ id: string, status: OrderStatus, amount: number, createdAt: Date, customer: Customer, metadata: JsonB }` | OrderTimeline, OrderCard, useOrders, GET /api/orders, order_service |

## Cross-Repo Interactions
| From → To | How | Endpoint | Request | Response |
|-----------|-----|----------|---------|----------|
| web GET /api/orders → payment-service | HTTP GET | `/orders/sync?org_id=` | `{ orgId, status? }` | `{ orders: Order[] }` |

## Tests
| File | Covers | Status |
|------|--------|--------|
| `__tests__/api/orders.test.ts` | GET /api/orders contract | exists |
| — | OrderTimeline component | missing |
| — | useOrders hook | missing |

## Commands
| Action | Command |
|--------|---------|
| Dev | `bun run dev:web` |
| Types | `bun run typecheck` |
| Test orders | `bun test -- __tests__/api/orders` |
| Payment service dev | `cd payment-service && flask run` |

## Existing Plans & Observations
| Path | Status | Key finding |
|------|--------|-------------|
| `.claude/plans/active/orders-migration/` | active | v2 payload migration in progress |

## Gotchas
Recency effect — these stick in memory.
- `orders.status` is a pgEnum — must use enum values, not raw strings (orders.ts:8)
- payment-service /orders/sync has 30s timeout — large orgs may hit it
- Import boundary: never import route.ts from client code (server-only, imports db)
- useOrders has staleTime: 5min — mutations need invalidateQueries to refresh
````

## Rules

- **Data flow first** — most valuable context gets primacy position. Always the first section after the header.
- **Semantic names as references** — `OrderTimeline`, `useOrders()`, `GET /api/orders`. Self-describing, no lookup tables.
- **Signatures not implementations** — export names, function signatures, param types, return shapes. Bodies are noise.
- **Inline types at point-of-use** — `useOrders() → { orders: Order[], total }`. Separate Types section only for shared complex types (3+ consumers).
- **Cap at ~40 files** — beyond this, mid-document recall degrades. Rank by relevance, cut the tail.
- **Agents are conditional** — under 20 files, scan directly. Agents add overhead (repeated instructions, synthesis cost).
- **Scan code, not just docs** — docs may be stale. Code is truth. Read actual exports, actual signatures.
- **Flag gaps** — missing tests, `any` types, TODO comments, stale docs. Gaps matter for planning.
- **Write to disk** — always write to `.claude/skills/hyperscan/scans/YYYY-MM-DD-[task-slug].md`.
- **Check existing scans** — reuse recent scans of the same area. Delta, don't rescan.
