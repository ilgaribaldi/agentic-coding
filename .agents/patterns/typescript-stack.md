# TypeScript Stack

## Core Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Runtime** | Bun | 1.1.42 |
| **Framework** | Next.js (App Router) | 15 |
| **API Routes** | Hono | latest |
| **ORM** | Drizzle ORM | 0.44+ |
| **Database** | Neon Serverless PostgreSQL | — |
| **Auth** | Clerk | 6.16+ |
| **Data Fetching** | TanStack Query | 5.62+ |
| **UI** | Shadcn/UI (Radix primitives) | — |
| **Styling** | Tailwind CSS | 3.x |
| **Charts** | Recharts | latest |
| **Forms** | React Hook Form + Zod | — |
| **Validation** | Zod | 3.24+ |
| **Mobile** | Expo SDK 55 + React Native 0.83 | — |
| **Desktop** | Electron 35 + Vite + React 19 | — |
| **Monorepo** | Turborepo | 2.3+ |
| **React** | 19.2 | — |

## Monorepo Layout

```
project/
├── apps/
│   ├── web/           # Next.js 15 (App Router)
│   ├── mobile/        # Expo SDK 55 (Expo Router)
│   └── desktop/       # Electron 35 (Vite + React)
├── packages/
│   ├── api/           # Zod schemas, React Query hooks, shared client
│   ├── db/            # Drizzle schema (source of truth, no runtime)
│   ├── ui/            # Shadcn components (70+ components)
│   ├── config/        # Tailwind preset, TypeScript base configs
│   ├── utils/         # Date, unit, alert, CSV, map utilities
│   └── constants/     # Weather, risk, agriculture constants
├── turbo.json         # Task pipeline
└── package.json       # Bun workspaces
```

## Naming Conventions

| Context | Convention |
|---------|-----------|
| All files | `kebab-case.tsx` |
| Component exports | `PascalCase` |
| Hook exports | `camelCase` (prefixed `use`) |
| Constants | `SCREAMING_SNAKE_CASE` |
| Database tables | `camelCase` (Drizzle convention) |
| API endpoints | `/kebab-case/path` |
| Package names | `@scope/kebab-case` |

## TypeScript Rules

- Never `any` — use `unknown`
- Use `!= null` for null+undefined checks
- Strict mode everywhere
- Path alias: `@/*` points to `src/`
- Cross-package imports: always `@scope/package-name` (never relative)

## Build Pipeline

```bash
bun run dev:web        # Web dev (Turbopack HMR, port 3000)
bun run dev:desktop    # Desktop (Vite port 5174 + Electron)
bun run dev:mobile     # Mobile (Expo)
bun run typecheck      # TypeScript check all apps
bun run build:web      # Production build
bun run db:generate    # Drizzle migration
bun run db:migrate     # Apply migrations
```

## Deployment

| App | Platform | Config |
|-----|----------|--------|
| Web | Vercel | `vercel.json` — `bun install`, `bun run build:web`, output `.next` |
| Desktop | electron-builder | Deep link protocol, auto-update, code signing |
| Mobile | EAS Build + EAS Submit | TestFlight / Google Play |

## Docs

- [Next.js 15 App Router](https://nextjs.org/docs/app)
- [Hono](https://hono.dev/docs/)
- [Drizzle ORM](https://orm.drizzle.team/docs/overview)
- [TanStack Query v5](https://tanstack.com/query/v5/docs/framework/react/overview)
- [Shadcn/UI](https://ui.shadcn.com/docs)
- [Clerk Next.js](https://clerk.com/docs/reference/nextjs/overview)
- [Turborepo](https://turbo.build/repo/docs)
- [Bun](https://bun.sh/docs)
