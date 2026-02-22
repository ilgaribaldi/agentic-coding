# Scan Example

A concrete example of a completed hyperscan output. This shows what a real scan file looks like when written to `scans/`.

---

```markdown
# Hyperscan: add bulk-delete endpoint for projects
Date: 2025-06-10 | Files: 18

## Data Flow
```
DELETE /api/projects/bulk (bulk-route.ts)
  -> validateBulkDelete(ids) (validators.ts)
  -> authz: requireScope("projects:write") (middleware.ts)
  -> bulkDeleteProjects(ids) (project-service.ts)
    -> BEGIN transaction (db.ts)
      -> DELETE attachments WHERE project_id IN (...) (attachments table)
      -> DELETE projects WHERE id IN (...) (projects table)
    -> COMMIT
  -> returns { deleted: number }
```

## Critical Entities
- [project-service.ts](src/services/project-service.ts): Core business logic — `createProject()`, `deleteProject()`, `listProjects()`. New `bulkDeleteProjects()` goes here.
- [projects.ts](src/db/schema/projects.ts): DB table — `{ id, name, ownerId, createdAt, archivedAt? }`, FK->users, has-many->attachments
- [middleware.ts](src/api/middleware.ts): Auth + scope checking — `requireScope(scope)` wraps all protected routes
- [validators.ts](src/api/validators.ts): Request validation — uses zod, exports per-route schemas

## File Map

### API layer
- [bulk-route.ts](src/api/routes/projects/bulk-route.ts): _does not exist yet_ — new file for `DELETE /api/projects/bulk`
- [routes/index.ts](src/api/routes/projects/index.ts): Route barrel — registers all project routes, needs to add bulk-route
- [middleware.ts](src/api/middleware.ts): Auth middleware — `requireAuth()`, `requireScope(scope)` -> checks JWT + permission scopes
- [validators.ts](src/api/validators.ts): Zod schemas — `createProjectSchema`, `updateProjectSchema`. Add `bulkDeleteSchema`.

### Service layer
- [project-service.ts](src/services/project-service.ts): CRUD operations — `createProject(data)`, `deleteProject(id)`, `listProjects(filter)`. Handles cascading deletes to attachments.
- [attachment-service.ts](src/services/attachment-service.ts): File ops — `deleteAttachment(id)`, `deleteByProject(projectId)`. Called by project-service on delete.

### Data layer
- [projects.ts](src/db/schema/projects.ts): `projects` table — `{ id, name, ownerId, createdAt, archivedAt? }`, FK->users
- [attachments.ts](src/db/schema/attachments.ts): `attachments` table — `{ id, projectId, url, size }`, FK->projects (CASCADE DELETE)
- [db.ts](src/db/db.ts): Connection pool + transaction helper — `db.transaction(async (tx) => { ... })`

### Types
- [types.ts](src/types/projects.ts): `Project`, `CreateProjectInput`, `ProjectFilter` — add `BulkDeleteInput`

### Tests
- [project-service.test.ts](tests/services/project-service.test.ts): Unit tests for CRUD — exists, needs bulk delete cases
- [projects-api.test.ts](tests/api/projects-api.test.ts): Integration tests for project endpoints — exists, needs bulk endpoint
- _missing_: Test for cascade behavior when bulk-deleting projects with attachments

## Shared Types
- `Project` defined at [types.ts](src/types/projects.ts): `{ id: string, name: string, ownerId: string, createdAt: Date, archivedAt?: Date }` — used by project-service, routes, tests

## Commands
| Action | Command |
|--------|---------|
| Dev server | `npm run dev` |
| Typecheck | `npm run typecheck` |
| Test projects | `npm test -- tests/services/project-service` |
| Migrations | `npm run db:migrate` |

## Gotchas
- `attachments` has CASCADE DELETE on `projectId` FK — but project-service also does manual cleanup for S3 files. Bulk delete must call `deleteByProject()` _before_ deleting the project row, or S3 files become orphans.
- `requireScope("projects:write")` is required — `projects:delete` does not exist as a separate scope.
- Max 100 IDs per bulk request — DB has a parameter limit of 65535 and each row uses ~5 params in the query.
```
