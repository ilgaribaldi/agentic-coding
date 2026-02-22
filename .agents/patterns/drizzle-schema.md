# Drizzle ORM Schema Patterns

## Table Definition

```typescript
import { pgTable, text, timestamp, real, integer, index, uniqueIndex, pgEnum, boolean, jsonb } from "drizzle-orm/pg-core"
import { relations } from "drizzle-orm"

// Enums at module level
export const statusEnum = pgEnum("status", ["ACTIVE", "INACTIVE", "PROCESSING", "ERROR"])

// Table with indexes in second parameter
export const items = pgTable(
  "item",
  {
    id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
    name: text("name"),
    latitude: real("latitude").notNull(),
    longitude: real("longitude").notNull(),
    status: statusEnum("status").default("INACTIVE").notNull(),
    organizationId: text("organizationId").references(() => organizations.id, { onDelete: "cascade" }),
    metadata: jsonb("metadata"),
    createdAt: timestamp("createdAt", { mode: "date" }).defaultNow().notNull(),
    updatedAt: timestamp("updatedAt", { mode: "date" }).defaultNow().notNull(),
    deletedAt: timestamp("deletedAt", { mode: "date" }),  // Soft deletes
  },
  (table) => ({
    createdAtIdx: index("item_created_at_idx").on(table.createdAt),
    orgIdIdx: index("item_org_id_idx").on(table.organizationId),
    statusIdx: index("item_status_idx").on(table.status),
  }),
)
```

## Relations

```typescript
export const itemsRelations = relations(items, ({ one, many }) => ({
  organization: one(organizations, {
    fields: [items.organizationId],
    references: [organizations.id],
  }),
  tags: many(itemTags),
}))
```

## Column Type Patterns

| Type | Pattern |
|------|---------|
| UUID PK | `text("id").primaryKey().$defaultFn(() => crypto.randomUUID())` |
| CUID2 PK | `text("id").primaryKey().$defaultFn(() => createId())` |
| Timestamps | `timestamp("createdAt", { mode: "date" }).defaultNow().notNull()` |
| Enums | `pgEnum("name", [...])` then `nameEnum("col").notNull()` |
| Numeric | `real("lat")`, `numeric("value")`, `integer("year")` |
| JSON | `jsonb("metadata")` |
| Geospatial | `geometry("geom", { type: "multipolygon", srid: 4326 }).notNull()` |
| FK | `text("orgId").references(() => orgs.id, { onDelete: "cascade" })` |
| Soft delete | `timestamp("deletedAt", { mode: "date" })` |

### CUID2 Primary Keys

CUID2 is a collision-resistant, sortable ID. Preferred over UUID for distributed systems:

```typescript
import { init } from "@paralleldrive/cuid2"

const createId = init({ length: 24 })

export const items = pgTable("item", {
  id: text("id").primaryKey().$defaultFn(() => createId()),
  // ...
})
```

**Why CUID2 over UUID**: Sortable by creation time, shorter, no dashes, database-index-friendly.

## Database Clients (Neon)

```typescript
import { drizzle as drizzleHttp } from "drizzle-orm/neon-http"
import { drizzle as drizzleServerless } from "drizzle-orm/neon-serverless"
import { neon, Pool } from "@neondatabase/serverless"

// HTTP client — fast single queries, NO transactions
const sql = neon(process.env.DATABASE_URL!)
export const db = drizzleHttp(sql)

// App reader role (RLS-scoped)
export const dbAppReader = drizzleHttp(neon(process.env.DATABASE_URL_APP_READER!))

// Pool client — WebSocket, REQUIRED for transactions
const pool = new Pool({ connectionString: process.env.DATABASE_URL })
export const dbPool = drizzleServerless(pool)
```

**Usage rule**: `db` for single queries (default), `dbPool` for transactions only.

```typescript
// Single query
const users = await db.select().from(users).where(eq(users.id, id))

// Transaction (MUST use dbPool)
await dbPool.transaction(async (tx) => {
  await tx.delete(table).where(eq(table.orgId, orgId))
  await tx.insert(table).values(newRows)
})
```

## Query Patterns

```typescript
import { db } from "@/db/drizzle"
import { eq, and, isNull, sql, count, desc, asc, like, inArray } from "drizzle-orm"

// Basic select
const items = await db.select().from(table).where(eq(table.id, id))

// With soft delete filter
const active = await db.select().from(items)
  .where(and(eq(items.orgId, orgId), isNull(items.deletedAt)))

// Count
const [{ total }] = await db.select({ total: count() }).from(items)

// Pagination
const results = await db.select().from(items)
  .where(eq(items.orgId, orgId))
  .orderBy(desc(items.createdAt))
  .limit(20).offset(0)

// Raw SQL for PostGIS
const point = `POINT(${lng} ${lat})`
const [country] = await db.select().from(regions)
  .where(sql`ST_Contains(${regions.geometry}, ST_SetSRID(ST_GeomFromText(${point}), 4326))`)
```

## Migration Workflow

```bash
bun run db:generate    # Generate SQL from schema changes
bun run db:migrate     # Apply to database
bun run db:studio      # Visual studio (browser)
```

**drizzle.config.ts**:
```typescript
import { defineConfig } from "drizzle-kit"
export default defineConfig({
  schema: "./src/schema/index.ts",
  dialect: "postgresql",
  dbCredentials: { url: process.env.DATABASE_URL! },
  verbose: true,
  strict: true,
  out: "./drizzle",
})
```

## Advanced Schema Patterns

### Materialized Paths (Tree Structures)

Store the full path as a column for fast tree queries without recursive joins:

```typescript
export const <nodes> = pgTable("<node>", {
  id: text("id").primaryKey().$defaultFn(() => createId()),
  name: text("name").notNull(),
  parentId: text("parentId").references(() => <nodes>.id, { onDelete: "cascade" }),
  path: text("path").notNull(),      // e.g., "/<root>/<parent>/<child>"
  depth: integer("depth").default(0).notNull(),
  ownerId: text("ownerId").notNull(),
}, (table) => ({
  ownerPathIdx: uniqueIndex("<node>_owner_path_idx").on(table.ownerId, table.path),
  parentIdx: index("<node>_parent_idx").on(table.parentId),
}))
```

**Query a subtree**: `WHERE path LIKE '/<root>/<parent>/%'`
**Move a subtree**: Update `path` prefix for all descendants in one query.
**Works for**: file trees, category hierarchies, org charts, nested comments, menu structures.

### Workspace Scoping (Multi-tenancy)

Scope data to personal or organization workspaces using nullable `orgId`:

```typescript
// Personal workspace: orgId IS NULL, scoped to user
const personal = await db.select().from(<table>)
  .where(and(eq(<table>.userId, userId), isNull(<table>.orgId)))

// Org workspace: orgId = specific org
const orgScoped = await db.select().from(<table>)
  .where(eq(<table>.orgId, orgId))
```

This pattern lets the same table serve both personal and team data without separate tables.

### Composite Unique Constraints

Prevent duplicates across multiple columns:

```typescript
export const <junction-table> = pgTable("<junction>", {
  id: text("id").primaryKey(),
  <fk-a>: text("<fk-a>").notNull(),
  <fk-b>: text("<fk-b>").notNull(),
  <attribute>: text("<attribute>").default("<default>").notNull(),
}, (table) => ({
  uniqueEntry: uniqueIndex("<junction>_unique").on(table.<fk-a>, table.<fk-b>),
}))
```

Use for: membership tables, tag assignments, unique slug-per-tenant, and any N:M relationship that should be deduplicated.

## Package Boundary

The `@scope/db` package exports **schema only** — no `process.env`, no connection logic, no runtime code. The DB client (`db`, `dbPool`) lives in the app's `src/db/drizzle.ts`.

## Docs

- [Drizzle Schema](https://orm.drizzle.team/docs/sql-schema-declaration)
- [Drizzle Relations](https://orm.drizzle.team/docs/rqb)
- [Drizzle Queries](https://orm.drizzle.team/docs/select)
- [Drizzle Kit](https://orm.drizzle.team/kit-docs/overview)
- [Neon Serverless Driver](https://neon.tech/docs/serverless/serverless-driver)
