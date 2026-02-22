# Scan Patterns

Glob and grep patterns for discovering relevant files. Use during Phase 2. Pick the section matching the detected stack — skip the rest.

## Table of Contents
- [Project Type Detection](#project-type-detection)
- [Language-Specific Patterns](#language-specific-patterns)
- [Generic Patterns](#generic-patterns)
- [Dependency Tracing](#dependency-tracing)

## Project Type Detection

Read root files to detect the stack:

| File | Indicates |
|------|-----------|
| `package.json` | JS/TS |
| `turbo.json`, `pnpm-workspace.yaml`, `lerna.json`, `nx.json` | JS/TS monorepo |
| `pyproject.toml`, `setup.py`, `requirements.txt` | Python |
| `go.mod` | Go |
| `Cargo.toml` | Rust |
| `pom.xml`, `build.gradle`, `build.gradle.kts` | Java/Kotlin |
| `Makefile`, `CMakeLists.txt` | C/C++ |
| `mix.exs` | Elixir |
| `Gemfile` | Ruby |
| `docker-compose.yml` | Multi-service |

For monorepos/workspaces, also read the workspace config to find all packages/apps.

## Language-Specific Patterns

### JavaScript / TypeScript
```
# Structure
Glob: **/package.json
Glob: **/tsconfig.json

# Source
Glob: **/*.{ts,tsx,js,jsx}       # broad — narrow with path if needed
Glob: **/src/**/*.{ts,tsx}
Glob: **/lib/**/*.{ts,tsx}

# Tests
Glob: **/*.test.{ts,tsx,js,jsx}
Glob: **/*.spec.{ts,tsx,js,jsx}
Glob: **/__tests__/**/*

# Exports/imports
Grep: "export (default |)(function|class|const|type|interface)" type:ts
Grep: "import .* from" type:ts
```

### Python
```
# Structure
Glob: **/pyproject.toml
Glob: **/__init__.py

# Source
Glob: **/*.py
Glob: **/src/**/*.py

# Tests
Glob: **/test_*.py
Glob: **/*_test.py
Glob: **/tests/**/*.py

# Exports/imports
Grep: "^(class |def |async def )" type:py
Grep: "^(from |import )" type:py
```

### Go
```
# Structure
Glob: go.mod
Glob: **/cmd/**/*.go

# Source
Glob: **/*.go
Glob: **/internal/**/*.go
Glob: **/pkg/**/*.go

# Tests
Glob: **/*_test.go

# Exports
Grep: "^(func |type |var |const )" type:go
```

### Rust
```
# Structure
Glob: **/Cargo.toml
Glob: **/src/lib.rs
Glob: **/src/main.rs

# Source
Glob: **/src/**/*.rs

# Tests
Glob: **/tests/**/*.rs
Grep: "#\[cfg\(test\)\]|#\[test\]" type:rust

# Exports
Grep: "^pub (fn|struct|enum|trait|mod|type|const)" type:rust
```

### Java / Kotlin
```
# Structure
Glob: **/pom.xml
Glob: **/build.gradle*

# Source
Glob: **/src/main/**/*.{java,kt}

# Tests
Glob: **/src/test/**/*.{java,kt}

# Exports
Grep: "^public (class|interface|enum|record)" type:java
Grep: "^(class |fun |object |interface |data class )" type:kotlin
```

### C / C++
```
# Structure
Glob: **/CMakeLists.txt
Glob: **/Makefile

# Source
Glob: **/*.{c,cpp,cc,h,hpp}
Glob: **/src/**/*.{c,cpp,cc}
Glob: **/include/**/*.{h,hpp}

# Tests
Glob: **/test*/**/*.{c,cpp}

# Exports
Grep: "^(class |struct |void |int |bool |auto |template)" glob:"*.{h,hpp}"
```

## Generic Patterns

Work across any project:

```
# Documentation
Glob: **/README.md
Glob: **/CLAUDE.md
Glob: **/docs/**/*.md

# Config / CI
Glob: **/.env.example
Glob: **/Dockerfile*
Glob: **/docker-compose*.yml
Glob: **/.github/workflows/*.yml

# Known issues
Grep: "TODO|FIXME|HACK|XXX"

# Schema / data (language-agnostic keywords)
Grep: "migration|schema|model|table" glob:"*.{ts,py,go,rs,java,kt}"
```

## Dependency Tracing

To map how files connect, trace from an entry point in both directions:

**Forward (what does it call?):**
1. Find entry points (main files, route handlers, CLI commands, exported APIs)
2. Read the entry point — note its imports/calls
3. Follow each import one level deep — note what _those_ call
4. Repeat until you reach a leaf (DB, filesystem, external API, output)

**Backward (what calls it?):**
1. Pick a target file or symbol
2. Grep for its name across the codebase to find all consumers
3. For each consumer, note the context (is it a component, a test, a service?)

**Cross-language / cross-service:**
1. Look for HTTP calls, RPC definitions, message queue producers/consumers
2. Grep for URLs, endpoint paths, service names, queue/topic names
3. Match producers to consumers across service boundaries
