# Scan Patterns Reference

Organized by scan phase. Use these patterns to systematically discover code.

## File Discovery Patterns

### TypeScript Monorepo

```
# Feature modules
apps/web/src/features/[name]/             → components/, hooks/, utils/, types.ts
apps/web/src/features/[name]/index.ts     → public exports
apps/mobile/features/[name]/              → mobile equivalent
apps/desktop/src/features/[name]/         → desktop equivalent

# API routes (Hono)
apps/web/src/app/api/[domain]/[[...route]]/route.ts  → main route file
apps/web/src/app/api/[domain]/[[...route]]/*.ts       → sub-route handlers

# Shared packages
packages/db/src/schema/[domain].ts        → DB schema + relations
packages/api/src/hooks/[domain].ts        → React Query hooks (shared web+mobile)
packages/api/src/schemas/[domain].ts      → Zod validation schemas
packages/constants/src/[domain]/          → Shared constants
packages/utils/src/[domain].ts            → Utility functions
packages/ui/src/components/               → UI component library

# Tests
apps/web/__tests__/                       → Contract + API tests
```

### Python Services

```
# Flask Microservice
app/main/controller/[name]_controller.py  → Flask route handlers
app/main/service/[name].py               → Business logic
app/main/model/[name].py                 → Data models

# Python SDK
[sdk_package]/client.py                   → Main client class
[sdk_package]/api.py                      → External API client

# Batch Processing
[jobs_package]/run_[name].py              → Job runners
[jobs_package]/config/                    → Job configs

# Workflow Orchestration
dags/[name].py                            → Airflow DAGs
```

## Content Search Patterns

### Tracing Data Flow
```
# Find where a function/hook is defined
Grep: "export (function|const) functionName"
Grep: "export default function"

# Find consumers
Grep: "import.*functionName"
Grep: "useFunctionName"

# Find API calls
Grep: "fetch\\(|api\\.|hc\\["  (Hono client calls)
Grep: "useQuery|useMutation|queryOptions"

# Find type definitions
Grep: "export (type|interface) TypeName"
Grep: "z\\.object|z\\.string|z\\.enum"  (Zod schemas)
```

### Cross-Repo Boundaries
```
# External service API calls (TS → microservice)
Grep: "API_BASE_URL|/api/v1/|service-name"

# System/orchestration endpoints
Grep: "/system/|systemRouter"

# Python SDK DB calls
Grep: "self\\.cursor|self\\.conn|execute\\("

# Webhook callbacks
Grep: "webhook|callback_url"
```

### Schema & Types
```
# Drizzle schema definitions
Grep: "pgTable|pgEnum|relations"

# Zod schemas
Grep: "z\\.object|createInsertSchema|createSelectSchema"

# TypeScript types shared between features
Grep: "export type|export interface" path=packages/
```

## Quick Diagnostic Commands

```bash
# File count per feature
find apps/web/src/features/[name] -type f | wc -l

# Recent changes in area
git log --oneline -15 -- <path>

# Dependencies between packages
grep -r "from '@scope/" packages/*/src/ | head -20

# Check for tests
find . -name "*.test.ts" -path "*[name]*"
```
