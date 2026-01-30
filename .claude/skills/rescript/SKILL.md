---
name: rescript
description: Use when working with ReScript (.res, .resi) files and you need accurate type signatures, function definitions, or module contents. Query indexed documentation from @rescript/runtime, @rescript/react, @rescript/webapi, or project packages. Prevents hallucination by looking up real API definitions instead of guessing.
---

# ReScript Database Skill

This skill provides access to indexed ReScript type information. Use it to look up accurate function signatures, type definitions, and module contents instead of guessing.

## Explicit Commands

When the user invokes `/rescript`, check what they want:

- `/rescript` or `/rescript query <something>` - Look up type/function info
- `/rescript sync` - Force a full database refresh
- `/rescript status` - Show database status (exists? how old?)

## When to Use This Skill

- Looking up function signatures from `@rescript/core`, `@rescript/react`, `@rescript/webapi`
- Finding what's available in a ReScript module
- Checking type definitions (records, variants, abstract types)
- Understanding functor-generated modules (like `PocketBase.BaseCollection`)
- Any time you're unsure about ReScript API details

## Prerequisites

The project must have:

1. A `rescript.json` file at the project root
2. Compiled ReScript artifacts in `lib/bs/` and `lib/ocaml/`

## How the Database Stays in Sync

The database uses `.cmi` (compiled module interface) hashes for invalidation. The `.cmi` only changes when a module's public API changes, so unnecessary re-indexing is avoided.

**Two modes:**

1. **Full sync** (`sync`) - Compiles the project, indexes all packages and dependencies. Run this for initial setup or after updating dependencies.
2. **Incremental update** (`update`) - Processes a single module by its JS output path. Designed to be called from `js-post-build` in `rescript.json`. Checks the `.cmi` hash and skips `rescript-tools doc` if unchanged.

When `js-post-build` is configured, the database stays in sync automatically during watch mode.

## Before Querying: Check Database Status

Before running queries, check if the database exists:

```bash
ls -la rescript.db 2>/dev/null && stat -f "%Sm" rescript.db
```

If `rescript.db` doesn't exist, a full sync is needed first.

## Commands

### Full Sync (manual)

Run from the repo root:

```bash
uv run .claude/skills/rescript/scripts/rescript-db.py sync
```

This will:

1. Compile ReScript (`bunx rescript`)
2. Index all modules, types, and values from all packages and dependencies
3. Create/update `rescript.db` in the current directory

Use this for:

- Initial database creation
- After updating dependencies (`bun install`)
- When the database is missing or corrupted

### Incremental Update (automatic via js-post-build)

Each `rescript.json` in the monorepo has a `js-post-build` hook configured:

```json
"js-post-build": {
  "cmd": "uv run ../../.claude/skills/rescript/scripts/rescript-db.py update"
}
```

The ReScript compiler appends the JS output path as the last argument. The script:

1. Extracts the module name from the path
2. Hashes `lib/ocaml/<Module>.cmi`
3. Skips if the hash matches what's stored in the db
4. Otherwise runs `rescript-tools doc` and upserts the module data

The script is written in Python because Python's `sqlite3` module has proper cross-process busy timeout support (via `sqlite3.connect(timeout=30)`), unlike Bun's SQLite which doesn't honor `PRAGMA busy_timeout` across processes. This is critical since the ReScript compiler fires `js-post-build` concurrently for multiple files.

If `rescript.db` doesn't exist, the update exits silently (run full sync first).

### Query Database

Run from the repo root:

```bash
uv run .claude/skills/rescript/scripts/rescript-db.py query "SELECT ..."
```

Returns JSON array of results. Only SELECT queries are allowed.

## Database Schema

### Tables Overview

```
packages -> modules -> types
                    -> values
                    -> aliases
```

### packages

| Column      | Type    | Description                                                |
| ----------- | ------- | ---------------------------------------------------------- |
| id          | INTEGER | Primary key                                                |
| name        | TEXT    | Package name (e.g., `@rescript/react`, `@rescript/webapi`) |
| path        | TEXT    | Filesystem path                                            |
| config_hash | TEXT    | For change detection                                       |

### modules

| Column           | Type    | Description                                                  |
| ---------------- | ------- | ------------------------------------------------------------ |
| id               | INTEGER | Primary key                                                  |
| package_id       | INTEGER | FK to packages                                               |
| parent_module_id | INTEGER | FK to parent module (for nested modules)                     |
| name             | TEXT    | Simple module name                                           |
| qualified_name   | TEXT    | Full path (e.g., `React`, `React.Children`, `DOMAPI-WebAPI`) |
| source_file_path | TEXT    | Path to .res/.resi file                                      |
| file_hash        | TEXT    | SHA-256 hash of the .cmi file (for invalidation)             |
| is_auto_opened   | INTEGER | 1 if globally available (Stdlib, Pervasives)                 |

**Note on qualified names**: Namespaced modules use hyphen format internally: `DOMAPI-WebAPI`, `FetchAPI-WebAPI`. In ReScript code you write `WebAPI.DOMAPI`. Nested modules use dots: `React.Children`.

### types

| Column    | Type    | Description                                     |
| --------- | ------- | ----------------------------------------------- |
| id        | INTEGER | Primary key                                     |
| module_id | INTEGER | FK to modules                                   |
| name      | TEXT    | Type name (e.g., `t`, `element`, `response`)    |
| kind      | TEXT    | `record`, `variant`, `abstract`, or NULL        |
| signature | TEXT    | Full type signature                             |
| detail    | TEXT    | JSON with record fields or variant constructors |

### values

| Column      | Type    | Description                                    |
| ----------- | ------- | ---------------------------------------------- |
| id          | INTEGER | Primary key                                    |
| module_id   | INTEGER | FK to modules                                  |
| name        | TEXT    | Function/value name                            |
| signature   | TEXT    | Full signature (e.g., `(string, int) => bool`) |
| param_count | INTEGER | Number of parameters                           |
| return_type | TEXT    | Return type                                    |

### aliases

| Column                | Type    | Description                  |
| --------------------- | ------- | ---------------------------- |
| source_module_id      | INTEGER | Module containing the alias  |
| alias_name            | TEXT    | The alias name               |
| alias_kind            | TEXT    | `type`, `value`, or `module` |
| target_qualified_name | TEXT    | What it points to            |

## Common Query Patterns

### Find a function by name

```sql
SELECT v.name, v.signature, v.param_count, m.qualified_name as module
FROM "values" v
JOIN modules m ON v.module_id = m.id
WHERE v.name = 'useState'
LIMIT 10
```

### Explore a module's contents

```sql
-- Get all values in a module
SELECT name, signature, param_count
FROM "values"
WHERE module_id = (SELECT id FROM modules WHERE qualified_name = 'React')
ORDER BY name

-- Get all types in a module
SELECT name, kind, signature
FROM types
WHERE module_id = (SELECT id FROM modules WHERE qualified_name = 'React')
ORDER BY name
```

### Search for modules by pattern

```sql
SELECT m.qualified_name, p.name as package
FROM modules m
JOIN packages p ON m.package_id = p.id
WHERE m.qualified_name LIKE '%Fetch%'
LIMIT 20
```

### Find functions by return type

```sql
SELECT v.name, v.signature, m.qualified_name as module
FROM "values" v
JOIN modules m ON v.module_id = m.id
WHERE v.return_type LIKE '%promise%'
LIMIT 20
```

### Check globally available symbols

```sql
SELECT m.qualified_name,
       (SELECT COUNT(*) FROM types WHERE module_id = m.id) as type_count,
       (SELECT COUNT(*) FROM "values" WHERE module_id = m.id) as value_count
FROM modules m
WHERE m.is_auto_opened = 1
```

### Find type details (record fields, variant constructors)

```sql
SELECT name, kind, signature, detail
FROM types
WHERE module_id = (SELECT id FROM modules WHERE qualified_name = 'FetchAPI-WebAPI')
  AND name = 'request'
```

The `detail` column contains JSON:

- For records: `{"items": [{"name": "field", "signature": "type"}]}`
- For variants: `{"items": [{"name": "Constructor", "signature": "payload"}]}`

### List all packages

```sql
SELECT name FROM packages ORDER BY name
```

## Query Strategy

1. **Start broad, then narrow**: First find the right module with a pattern search, then query that specific module for details.

2. **Two-phase lookup**:
   - Phase 1: `SELECT qualified_name FROM modules WHERE qualified_name LIKE '%Search%' LIMIT 10`
   - Phase 2: `SELECT * FROM "values" WHERE module_id = (SELECT id FROM modules WHERE qualified_name = 'ExactModule')`

3. **Quote "values"**: The table name `values` is a SQL keyword - always quote it as `"values"`.

## Common Packages

| Package             | Description                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------------- |
| `@rescript/runtime` | Core types (int, string, array, option, etc.)                                               |
| `@rescript/core`    | Standard library (Array, String, Option, Result) - modules have `Stdlib_` prefix internally |
| `@rescript/react`   | React bindings                                                                              |
| `@rescript/webapi`  | Browser APIs - modules use `-WebAPI` suffix (e.g., `DOMAPI-WebAPI`)                         |

## Important: Verify Before Writing Code

**Never assume you know ReScript APIs.** The bindings often differ from JavaScript:

- Different function names
- Different parameter order
- Labeled arguments where JS uses positional
- Types that don't exist in JS

Always query the database to get the actual signature before writing code.

## Important: Check Module Accessibility

When providing usage examples, always check if the module requires an `open` statement:

```sql
SELECT qualified_name, is_auto_opened FROM modules WHERE qualified_name = 'Global-WebAPI'
```

- `is_auto_opened = 1`: Module is globally available (e.g., `Stdlib`, `Pervasives`)
- `is_auto_opened = 0`: Module requires either:
  - `open ParentModule` (e.g., `open WebAPI` to access `Global.fetch`)
  - Fully qualified access (e.g., `WebAPI.Global.fetch`)

Most `@rescript/webapi` modules are **not** auto-opened and require `open WebAPI` or full qualification.
