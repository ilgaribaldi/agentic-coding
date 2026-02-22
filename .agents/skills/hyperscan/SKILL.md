---
name: hyperscan
description: "Deep, exhaustive codebase scan that maps every relevant file, component, route, schema, test, and interaction for a given task. Produces a compact, token-efficient context map with file-level descriptions and data flow diagrams — ready for implementation without further discovery. Use when starting complex tasks, before planning, or when you need complete understanding of how a feature area works. Trigger: /hyperscan followed by a task description."
---

# Hyperscan

Exhaustive codebase scan. Produces a compact context map: file descriptions + data flow — enough to implement without further discovery.

## Workflow

### Phase 0: Scope

Extract task from user message. Determine:
- Which areas of the codebase are involved
- Which feature areas, API routes, DB tables, packages are relevant
- Whether the task spans multiple packages/services

Check for existing scans first: `Glob: scans/*.md` (relative to this skill's directory). If a recent scan covers the same area, load it and do a delta — don't rescan from scratch.

### Phase 1: Triage (fast, parallel reads)

Discover project structure from root-level signals. Read in parallel whatever exists:
- Root config files: `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `pom.xml`
- Workspace/monorepo configs: `turbo.json`, `pnpm-workspace.yaml`, `lerna.json`, `nx.json`
- Project docs: `README.md`, `CLAUDE.md`, `CONTRIBUTING.md`
- Existing plans or observations: `Glob: **/task_plan.md`, `Glob: **/progress.md`

Use these to build a mental model of the project layout, tech stack, and conventions.

After triage, estimate file count. This determines Phase 2 strategy:
- **Under 20 files**: Scan directly — read files yourself.
- **20-50 files**: Spawn 2-3 parallel subagents to divide the work.
- **50+ files or 3+ packages**: Spawn 3-5 parallel subagents.

### Phase 2: Deep Scan

For every relevant file, capture what it **does** and how it **connects** to other files. Do NOT read full function bodies — exports, signatures, and relationships = 90% of what's needed at 10% of the tokens.

Consult these references within this skill as needed:
- `references/scan-patterns.md` — glob/grep patterns by language and project type
- `references/scan-example.md` — concrete example of a completed scan output

**Scanning approach:**

1. Use Glob and Grep to discover all candidate files relevant to the task
2. Read files to extract: exports, function signatures, type shapes, imports, key constants
3. For each file, note what it depends on and what depends on it
4. Trace the primary data flow end-to-end (entry point -> processing -> storage/output)

**Scaling strategy by file count:**
- **Under 20 files**: Read files directly. No need to parallelize.
- **20+ files**: Partition the discovered files into 2-5 non-overlapping groups (by directory, by concern, by package — whatever makes sense). Spawn one subagent per group in parallel. Each subagent gets its file list and returns `[filename](path): description` entries + any connections it finds.

Subagent missions should be derived from the actual project structure discovered in Phase 1 — not from a fixed template. Partition by whatever boundaries the codebase uses (directories, packages, services, modules).

### Phase 3: Synthesize

Merge findings into the output format below. Write to:
```
{this-skill-directory}/scans/YYYY-MM-DD-{task-slug}.md
```
Use today's date + kebab-case slug (e.g., `scans/2025-01-15-implement-user-dashboard.md`).

Relevance filter: cap at ~40 files. If more were discovered, rank by relevance to the task (files that will be modified > files that are called > files that are tangentially related). Cut the tail.

### Phase 4: Present

Show user a brief summary:
- Areas/packages involved
- File count mapped
- Key architectural insight or gotcha
- Path to full scan file
- Suggested next step

## Output Format

Highest-value info at top (primacy effect), gotchas at bottom (recency effect), file map in middle.

### Formatting Rules

- **File entries**: `[<filename>](<path>): <what it does / why it's relevant>`
- **Full path on first mention**, semantic name thereafter
- **Inline connections**: `[<file>](<path>): <description> — uses <X>, calls <Y>`
- **No prose**: Lists, code blocks, tables only
- **Signatures not bodies**: Export names, function signatures with param/return types. Not implementations.
- **Abbreviate**: `FK` not "foreign key", `->` not "calls", `?` for optional

### Template

````markdown
# Hyperscan: <task summary>
Date: YYYY-MM-DD | Files: N

## Data Flow
Trace the primary flow(s) relevant to the task end-to-end.
```
<entry point> (<file>)
  -> <step 2> (<file>)
    -> <step 3> (<file>)
      -> <storage/output/side-effect>
      -> returns <shape>
```

## Critical Entities
Top 3-5 items the implementer must understand.
- [<file>](<path>): <what it is> — <key signature or shape>, <connections>
- [<file>](<path>): <what it is> — <key signature or shape>, <connections>

## File Map
Group by whatever boundaries the codebase uses (directories, packages, modules, layers).

### <group name>
- [<file>](<path>): <what it does> — <connections to other files>
- [<file>](<path>): <what it does> — <connections to other files>

### <group name>
- [<file>](<path>): <what it does> — <connections to other files>

### Tests
- [<file>](<path>): <what it covers> — exists
- _missing_: <untested area>

## Shared Types
Only include if complex types are used in 3+ places.
- `<TypeName>` defined at [<file>](<path>): `<shape>` — used by <A>, <B>, <C>

## Commands
Relevant dev/build/test commands discovered from project config.
| Action | Command |
|--------|---------|
| <action> | `<command>` |

## Gotchas
Anything that would surprise or trip up an implementer.
- <gotcha 1>
- <gotcha 2>
````

## Rules

- **Data flow first** — most valuable context gets primacy position. Always the first section after the header.
- **`[filename](path): description` format** — every file entry follows this pattern. Self-describing, clickable.
- **Signatures not implementations** — export names, function signatures, param/return types. Bodies are noise.
- **Cap at ~40 files** — beyond this, mid-document recall degrades. Rank by relevance, cut the tail.
- **Parallelize only when needed** — under 20 files, scan directly. Subagents add overhead.
- **Scan code, not just docs** — docs may be stale. Code is truth. Read actual exports, actual signatures.
- **Flag gaps** — missing tests, `any` types, TODO comments. Gaps matter for planning.
- **Write to disk** — always write to `scans/YYYY-MM-DD-{task-slug}.md` within this skill's directory.
- **Check existing scans** — reuse recent scans of the same area. Delta, don't rescan.
- **Stay portable** — never hardcode project-specific paths. Discover structure from root config files.
