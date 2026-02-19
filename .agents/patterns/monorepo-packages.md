# Monorepo & Packages

## Workspace Config

```json
// package.json (root)
{
  "private": true,
  "workspaces": ["apps/*", "packages/*"],
  "packageManager": "bun@1.1.42",
  "overrides": {
    "react": "19.2.4",
    "react-dom": "19.2.4",
    "react-is": "19.2.4"
  }
}
```

## Turborepo Pipeline

```json
// turbo.json
{
  "globalEnv": ["NEXT_PUBLIC_*", "VITE_*"],
  "tasks": {
    "build": { "dependsOn": ["^build"], "outputs": [".next/**", "dist/**"] },
    "dev": { "cache": false, "persistent": true },
    "typecheck": { "dependsOn": ["^build"] },
    "test": { "dependsOn": ["^build"] }
  }
}
```

- `^build` = upstream packages build first
- `dev` is non-cached, persistent (HMR)
- `env` array lists vars that affect build cache

## Package Exports Pattern

Each package uses explicit `exports` in `package.json`:

```json
{
  "name": "@scope/api",
  "exports": {
    "./client": "./src/client/index.ts",
    "./schemas": "./src/schemas/index.ts",
    "./schemas/*": "./src/schemas/*.ts",
    "./hooks": "./src/hooks/index.ts",
    "./hooks/*": "./src/hooks/*.ts"
  },
  "peerDependencies": {
    "@tanstack/react-query": ">=5.0.0",
    "react": ">=18.0.0"
  }
}
```

**Import convention** — prefer subpath for tree-shaking:

```typescript
// Good: subpath imports
import { locationSchema } from "@scope/api/schemas/locations"
import { useGetLocations } from "@scope/api/hooks/locations"
import { Button } from "@scope/ui/button"
import { formatDate } from "@scope/utils/dates"
import { statusOptions } from "@scope/constants/lookup"

// Avoid: barrel imports (less tree-shakeable)
import { locationSchema } from "@scope/api"
```

## Package Responsibilities

| Package | Exports | Boundary |
|---------|---------|----------|
| `@scope/db` | Drizzle schema, types | **No runtime** — no `process.env`, no connection code |
| `@scope/api` | Zod schemas, React Query hooks, shared client | Peer deps on React + TanStack |
| `@scope/ui` | Shadcn components (`*.tsx`) | Peer deps on React, Tailwind, lucide-react |
| `@scope/config` | Tailwind preset, TypeScript base configs | Pure config — no React deps |
| `@scope/utils` | Date, unit, alert, CSV, map utilities | Depends on `@scope/api` + `@scope/constants` |
| `@scope/constants` | Weather, risk, agriculture constants | **Pure constants** — no server deps |

## Import Boundaries

- **Never** relative paths across package boundaries
- **Always** `@scope/package-name` for cross-package imports
- `packages/` must never import from `apps/`
- Apps can import from any package
- **Never** import API route files from client components (they import `db` which crashes in browser)

## TypeScript Config

Shared base in `packages/config/typescript/base.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "target": "ES2017",
    "skipLibCheck": true,
    "incremental": true
  }
}
```

Apps extend with path aliases:

```json
// apps/web/tsconfig.json
{
  "compilerOptions": {
    "paths": { "@/*": ["./src/*"] }
  }
}
```

## React Deduplication (Electron)

Electron apps need explicit deduplication to prevent multiple React instances:

```typescript
// vite.config.ts
resolve: {
  alias: {
    "react": path.resolve(rootNodeModules, "react"),
    "react-dom": path.resolve(rootNodeModules, "react-dom"),
  },
  dedupe: ["react", "react-dom"],
}
```

## Docs

- [Turborepo](https://turbo.build/repo/docs)
- [Bun Workspaces](https://bun.sh/docs/install/workspaces)
- [Package Exports](https://nodejs.org/api/packages.html#exports)
