#!/usr/bin/env -S uv run --script
"""
ReScript Database CLI

A CLI for syncing and querying ReScript project databases.
Used by the Claude Code rescript skill.

Usage:
    uv run rescript-db.py sync [project_root]       - Sync/create the database
    uv run rescript-db.py update <js-output-path>    - Incremental update (js-post-build)
    uv run rescript-db.py query "SELECT ..."         - Run a SELECT query
"""

import hashlib
import json
import os
import re
import sqlite3
import subprocess
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from glob import glob as file_glob
from pathlib import Path

# =============================================================================
# Constants
# =============================================================================

MAX_WORKERS = 12

SCHEMA_DDL = """
CREATE TABLE IF NOT EXISTS packages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    path TEXT NOT NULL,
    rescript_json TEXT NOT NULL,
    config_hash TEXT
);

CREATE TABLE IF NOT EXISTS modules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    package_id INTEGER NOT NULL,
    parent_module_id INTEGER,
    name TEXT NOT NULL,
    qualified_name TEXT NOT NULL UNIQUE,
    source_file_path TEXT NOT NULL,
    compiled_file_path TEXT NOT NULL,
    file_hash TEXT,
    is_auto_opened INTEGER DEFAULT 0,
    FOREIGN KEY (package_id) REFERENCES packages(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_module_id) REFERENCES modules(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS types (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    kind TEXT,
    signature TEXT,
    detail TEXT,
    FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "values" (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    module_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    return_type TEXT,
    param_count INTEGER DEFAULT 0,
    signature TEXT,
    detail TEXT,
    FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS aliases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_module_id INTEGER NOT NULL,
    alias_name TEXT NOT NULL,
    alias_kind TEXT NOT NULL,
    target_qualified_name TEXT NOT NULL,
    docstrings TEXT,
    FOREIGN KEY (source_module_id) REFERENCES modules(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_modules_package ON modules(package_id);
CREATE INDEX IF NOT EXISTS idx_modules_parent ON modules(parent_module_id);
CREATE INDEX IF NOT EXISTS idx_modules_qualified ON modules(qualified_name);
CREATE INDEX IF NOT EXISTS idx_modules_compiled_path ON modules(compiled_file_path);
CREATE INDEX IF NOT EXISTS idx_types_module ON types(module_id);
CREATE INDEX IF NOT EXISTS idx_values_module ON "values"(module_id);
CREATE INDEX IF NOT EXISTS idx_aliases_name ON aliases(alias_name);
CREATE INDEX IF NOT EXISTS idx_aliases_source ON aliases(source_module_id);
CREATE INDEX IF NOT EXISTS idx_modules_auto_opened ON modules(is_auto_opened);
"""

# =============================================================================
# Hash Utilities
# =============================================================================


def hash_file(path: str) -> str | None:
    try:
        h = hashlib.sha256()
        with open(path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return h.hexdigest()
    except OSError:
        return None


def read_compiler_info(package_path: str) -> dict | None:
    try:
        p = os.path.join(package_path, "lib", "bs", "compiler-info.json")
        with open(p) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def get_package_config_hash(package_path: str) -> str | None:
    info = read_compiler_info(package_path)
    return info.get("rescript_config_hash") if info else None


def get_runtime_path(package_path: str) -> str | None:
    info = read_compiler_info(package_path)
    return info.get("runtime_path") if info else None


# =============================================================================
# ReScript JSON Parsing
# =============================================================================

_rescript_json_cache: dict[str, dict] = {}


def parse_rescript_json(package_path: str) -> dict:
    if package_path in _rescript_json_cache:
        return _rescript_json_cache[package_path]
    try:
        p = os.path.join(package_path, "rescript.json")
        with open(p) as f:
            data = json.load(f)
        _rescript_json_cache[package_path] = data
        return data
    except (OSError, json.JSONDecodeError):
        fallback = {"sources": ["src"]}
        _rescript_json_cache[package_path] = fallback
        return fallback


def _get_source_dirs(config: dict) -> list[str]:
    sources = config.get("sources", ["src"])
    dirs: list[str] = []
    if isinstance(sources, str):
        dirs.append(sources)
    elif isinstance(sources, list):
        for s in sources:
            if isinstance(s, str):
                dirs.append(s)
            elif isinstance(s, dict) and "dir" in s:
                dirs.append(s["dir"])
    elif isinstance(sources, dict) and "dir" in sources:
        dirs.append(sources["dir"])
    return dirs


# =============================================================================
# File Discovery
# =============================================================================


def find_source_file(compiled_file_path: str, package_path: str) -> str:
    """Find the actual source file for a compiled file in lib/ocaml/."""
    file_name = os.path.basename(compiled_file_path)

    if "@rescript/runtime" in compiled_file_path:
        return compiled_file_path

    config = parse_rescript_json(package_path)
    source_dirs = _get_source_dirs(config)

    for source_dir in source_dirs:
        source_dir_path = os.path.join(package_path, source_dir)
        matches = file_glob(
            os.path.join(source_dir_path, "**", file_name), recursive=True
        )
        for match in matches:
            if match.endswith(".res"):
                resi = match[:-4] + ".resi"
                if os.path.isfile(resi):
                    return resi
            return match

    return compiled_file_path


def get_rescript_files(directory: str) -> list[str]:
    """Get .res/.resi files from lib/ocaml/, preferring .resi over .res."""
    ocaml_dir = os.path.join(directory, "lib", "ocaml")
    if not os.path.isdir(ocaml_dir):
        return []

    res_files = file_glob(os.path.join(ocaml_dir, "*.res"))
    resi_files = file_glob(os.path.join(ocaml_dir, "*.resi"))
    resi_set = set(resi_files)

    filtered = []
    for f in resi_files:
        filtered.append(f)
    for f in res_files:
        resi = f[:-4] + ".resi"
        if resi not in resi_set:
            filtered.append(f)

    return filtered


def find_rescript_projects(start_dir: str) -> list[dict]:
    """Find all rescript.json files under start_dir (excluding node_modules)."""
    projects = []
    for p in Path(start_dir).rglob("rescript.json"):
        if "node_modules" in p.parts:
            continue
        try:
            with open(p) as f:
                content = json.load(f)
            project_dir = str(p.parent)
            projects.append(
                {
                    "path": project_dir,
                    "name": content.get("name", ""),
                    "dependencies": content.get("dependencies", []),
                    "rescriptJson": content,
                }
            )
        except (OSError, json.JSONDecodeError) as ex:
            print(f"Failed to parse {p}: {ex}", file=sys.stderr)
    return projects


# =============================================================================
# Package Resolution
# =============================================================================


def _resolve_package_from_bun_isolated(
    package_name: str, project_root: str
) -> str | None:
    """Search bun's isolated install cache for a package."""
    bun_cache_dir = os.path.join(project_root, "node_modules", ".bun")
    if not os.path.isdir(bun_cache_dir):
        return None

    dir_pattern = package_name.replace("/", "+")
    # glob: <dir_pattern>@*/node_modules/<package_name>
    pattern = os.path.join(
        bun_cache_dir, f"{dir_pattern}@*", "node_modules", package_name
    )
    matches = file_glob(pattern)

    latest_match = None
    latest_mtime = 0.0
    for match in matches:
        if os.path.isdir(match):
            mtime = os.path.getmtime(match)
            if mtime > latest_mtime:
                latest_mtime = mtime
                latest_match = match

    return latest_match


def resolve_package(package_name: str, project_root: str) -> dict | None:
    """Resolve a ReScript package by name, checking node_modules and bun cache."""
    is_runtime = package_name == "@rescript/runtime"

    # Try standard node_modules resolution
    standard_path = os.path.join(project_root, "node_modules", package_name)
    if os.path.isdir(standard_path):
        config_file = "package.json" if is_runtime else "rescript.json"
        config_path = os.path.join(standard_path, config_file)
        if os.path.isfile(config_path):
            rescript_json = {"name": package_name} if is_runtime else None
            if not is_runtime:
                try:
                    with open(config_path) as f:
                        rescript_json = json.load(f)
                except (OSError, json.JSONDecodeError):
                    return None
            return {
                "path": standard_path,
                "name": package_name,
                "rescriptJson": rescript_json,
            }

    # Try bun isolated cache
    isolated_path = _resolve_package_from_bun_isolated(package_name, project_root)
    if isolated_path:
        rescript_json = {"name": package_name} if is_runtime else None
        if not is_runtime:
            try:
                rj_path = os.path.join(isolated_path, "rescript.json")
                with open(rj_path) as f:
                    rescript_json = json.load(f)
            except (OSError, json.JSONDecodeError):
                print(
                    f"Could not read rescript.json for {package_name} from bun cache",
                    file=sys.stderr,
                )
                return None
        return {
            "path": isolated_path,
            "name": package_name,
            "rescriptJson": rescript_json,
        }

    print(
        f"Could not resolve package {package_name}: not found in node_modules or .bun cache",
        file=sys.stderr,
    )
    return None


# =============================================================================
# Documentation Extraction
# =============================================================================


def extract_documentation(
    file_path: str, cwd: str, env: dict | None = None
) -> list[dict]:
    """Run rescript-tools doc and parse the JSON output."""
    spawn_env = None
    if env:
        spawn_env = {**os.environ, **env}
    try:
        result = subprocess.run(
            ["bunx", "rescript-tools", "doc", file_path],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=30,
            env=spawn_env,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return []

    if result.returncode != 0:
        return []

    try:
        doc_json = json.loads(result.stdout)
    except json.JSONDecodeError:
        return []

    return parse_module_documentation(doc_json, file_path)


def extract_documentation_batch(
    files: list[str], package_dir: str, env: dict | None = None
) -> dict[str, list[dict]]:
    """Extract documentation for multiple files in parallel."""
    results: dict[str, list[dict]] = {}
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as pool:
        futures = {
            pool.submit(extract_documentation, f, package_dir, env): f for f in files
        }
        for future in as_completed(futures):
            f = futures[future]
            try:
                results[f] = future.result()
            except Exception:
                results[f] = []
    return results


def parse_module_documentation(doc_json, file_path: str) -> list[dict]:
    """Parse rescript-tools doc JSON into a list of module dicts."""
    modules = []

    def process_module(item, parent_qualified_name=None):
        kind = item.get("kind")
        if kind not in ("module", "moduleType"):
            return None

        name = item["name"]
        qualified_name = (
            f"{parent_qualified_name}.{name}" if parent_qualified_name else name
        )

        types: list[dict] = []
        values: list[dict] = []
        aliases: list[dict] = []
        nested_modules: list[dict] = []

        module = {
            "name": name,
            "qualifiedName": qualified_name,
            "sourceFilePath": file_path,
            "types": types,
            "values": values,
            "aliases": aliases,
            "nestedModules": nested_modules,
        }

        for child in item.get("items", []):
            child_kind = child.get("kind")

            if child_kind == "type":
                detail = child.get("detail") or {}
                types.append(
                    {
                        "name": child["name"],
                        "kind": detail.get("kind"),
                        "signature": child.get("signature"),
                        "detail": detail,
                    }
                )
            elif child_kind == "value":
                sig = child.get("signature") or ""
                param_count = len(re.findall(r"=>", sig))
                values.append(
                    {
                        "name": child["name"],
                        "signature": sig or None,
                        "paramCount": param_count,
                        "returnType": None,
                        "detail": child.get("detail") or {},
                    }
                )
            elif child_kind in ("module", "moduleType"):
                if child.get("item"):
                    aliases.append(
                        {
                            "name": child["name"],
                            "kind": "module",
                            "targetQualifiedName": child["item"].get("name")
                            or child["name"],
                            "docstrings": child.get("docstrings", []),
                        }
                    )
                else:
                    nested = process_module(child, qualified_name)
                    if nested:
                        nested_modules.append(nested)
            elif child_kind == "typeAlias":
                aliases.append(
                    {
                        "name": child["name"],
                        "kind": "type",
                        "targetQualifiedName": child.get("signature") or child["name"],
                        "docstrings": child.get("docstrings", []),
                    }
                )

        return module

    if isinstance(doc_json, list):
        for item in doc_json:
            m = process_module(item)
            if m:
                modules.append(m)
    elif isinstance(doc_json, dict) and "name" in doc_json and "items" in doc_json:
        m = process_module({**doc_json, "kind": "module"})
        if m:
            modules.append(m)

    return modules


# =============================================================================
# Monorepo Root Discovery
# =============================================================================


def find_monorepo_root(package_dir: str) -> str | None:
    """Walk up from package_dir looking for a parent rescript.json that lists
    this package in its dependencies."""
    config_path = os.path.join(package_dir, "rescript.json")
    try:
        with open(config_path) as f:
            config = json.load(f)
    except (OSError, json.JSONDecodeError):
        return None

    pkg_name = config.get("name")
    if not pkg_name:
        return None

    d = os.path.dirname(os.path.abspath(package_dir))
    while True:
        parent_config = os.path.join(d, "rescript.json")
        try:
            with open(parent_config) as f:
                parent = json.load(f)
            deps = (
                parent.get("dependencies", [])
                + parent.get("dev-dependencies", [])
                + parent.get("bs-dependencies", [])
                + parent.get("bs-dev-dependencies", [])
            )
            if pkg_name in deps:
                return d
        except (OSError, json.JSONDecodeError):
            # Config file missing or invalid; continue searching parent directories
            pass
        parent_d = os.path.dirname(d)
        if parent_d == d:
            return None
        d = parent_d


def find_db_path(project_root: str) -> str | None:
    """Find rescript.db: check cwd first, then walk up to monorepo root."""
    local_db = os.path.join(project_root, "rescript.db")
    if os.path.isfile(local_db):
        return local_db

    root = find_monorepo_root(project_root)
    if root:
        db_path = os.path.join(root, "rescript.db")
        if os.path.isfile(db_path):
            return db_path

    return None


# =============================================================================
# Database
# =============================================================================


def get_db_path(project_root: str) -> str:
    if not os.path.isdir(project_root):
        raise RuntimeError(f"Project directory does not exist: {project_root}")
    rescript_json = os.path.join(project_root, "rescript.json")
    if not os.path.isfile(rescript_json):
        raise RuntimeError(
            f"No rescript.json found at: {project_root}. "
            "The projectRoot must point to a directory containing a top-level rescript.json file."
        )
    return os.path.join(project_root, "rescript.db")


def init_database(project_root: str) -> sqlite3.Connection:
    db_path = get_db_path(project_root)
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA busy_timeout=5000")
    conn.executescript(SCHEMA_DDL)
    conn.commit()
    return conn


def insert_module_recursive(
    cur: sqlite3.Cursor,
    module: dict,
    package_id: int,
    parent_module_id: int | None,
    compiled_file_path: str,
    file_hash: str,
    source_file_path: str,
):
    """Insert a module and its types/values/aliases/nested modules."""
    try:
        cur.execute(
            "INSERT INTO modules (package_id, parent_module_id, name, qualified_name, "
            "source_file_path, compiled_file_path, file_hash, is_auto_opened) "
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?) RETURNING id",
            (
                package_id,
                parent_module_id,
                module["name"],
                module["qualifiedName"],
                source_file_path or module["sourceFilePath"],
                compiled_file_path,
                file_hash,
                0,
            ),
        )
        row = cur.fetchone()
        module_id = row[0]
    except sqlite3.IntegrityError:
        cur.execute(
            "SELECT id FROM modules WHERE qualified_name = ?",
            (module["qualifiedName"],),
        )
        row = cur.fetchone()
        if row:
            module_id = row[0]
        else:
            return

    for t in module["types"]:
        cur.execute(
            "INSERT INTO types (module_id, name, kind, signature, detail) VALUES (?, ?, ?, ?, ?)",
            (module_id, t["name"], t["kind"], t["signature"], json.dumps(t["detail"])),
        )

    for v in module["values"]:
        cur.execute(
            'INSERT INTO "values" (module_id, name, return_type, param_count, signature, detail) '
            "VALUES (?, ?, ?, ?, ?, ?)",
            (
                module_id,
                v["name"],
                v["returnType"],
                v["paramCount"],
                v["signature"],
                json.dumps(v["detail"]),
            ),
        )

    for a in module.get("aliases", []):
        cur.execute(
            "INSERT INTO aliases (source_module_id, alias_name, alias_kind, "
            "target_qualified_name, docstrings) VALUES (?, ?, ?, ?, ?)",
            (
                module_id,
                a["name"],
                a["kind"],
                a["targetQualifiedName"],
                json.dumps(a["docstrings"]),
            ),
        )

    for nested in module["nestedModules"]:
        insert_module_recursive(
            cur,
            nested,
            package_id,
            module_id,
            compiled_file_path,
            file_hash,
            source_file_path,
        )


# =============================================================================
# Auto-Opened Module Detection
# =============================================================================

BUILTIN_TYPES = [
    ("int", "unknown", "type int"),
    ("char", "unknown", "type char"),
    ("float", "unknown", "type float"),
    ("bool", "unknown", "type bool"),
    ("unit", "unknown", "type unit"),
    ("string", "unknown", "type string"),
    ("bigint", "unknown", "type bigint"),
    ("unknown", "unknown", "type unknown"),
    ("exn", "unknown", "type exn"),
    ("array", "unknown", "type array<'a>"),
    ("list", "unknown", "type list<'a>"),
    ("option", "unknown", "type option<'a>"),
    ("result", "unknown", "type result<'a, 'b>"),
    ("dict", "unknown", "type dict<'a>"),
    ("promise", "unknown", "type promise<'a>"),
    ("extension_constructor", "unknown", "type extension_constructor"),
]


def detect_and_mark_auto_opened(
    cur: sqlite3.Cursor,
    pkg: dict,
    package_id: int,
):
    if pkg["name"] == "@rescript/runtime":
        cur.execute(
            "UPDATE modules SET is_auto_opened = 1 WHERE qualified_name = ?",
            ("Stdlib",),
        )
        cur.execute(
            "UPDATE modules SET is_auto_opened = 1 WHERE qualified_name = ?",
            ("Pervasives",),
        )

        cur.execute(
            "SELECT id FROM modules WHERE qualified_name = 'Pervasives' AND package_id = ?",
            (package_id,),
        )
        row = cur.fetchone()
        if row:
            pervasives_id = row[0]
            for name, kind, signature in BUILTIN_TYPES:
                cur.execute(
                    "SELECT id FROM types WHERE module_id = ? AND name = ? AND signature = ?",
                    (pervasives_id, name, signature),
                )
                if not cur.fetchone():
                    cur.execute(
                        "INSERT INTO types (module_id, name, kind, signature, detail) "
                        "VALUES (?, ?, ?, ?, ?)",
                        (
                            pervasives_id,
                            name,
                            kind,
                            signature,
                            json.dumps({"builtin": True, "source": "compiler"}),
                        ),
                    )
        return

    compiler_flags = pkg.get("rescriptJson", {}).get("compiler-flags", [])
    opened_modules = [
        flag.replace("-open ", "").strip()
        for flag in compiler_flags
        if flag.startswith("-open ")
    ]
    for module_name in opened_modules:
        cur.execute(
            "UPDATE modules SET is_auto_opened = 1 WHERE qualified_name = ?",
            (module_name,),
        )


# =============================================================================
# Sync Command
# =============================================================================


def sync_database(project_root: str):
    start_time = time.monotonic()
    print("Starting ReScript database sync...", file=sys.stderr)

    conn = init_database(project_root)
    try:
        cur = conn.cursor()

        # Compile
        print("Compiling ReScript...", file=sys.stderr)
        result = subprocess.run(
            ["bunx", "rescript"],
            cwd=project_root,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"ReScript compilation failed: {result.stderr or 'Unknown error'}"
            )

        # Discover projects
        print("Discovering ReScript projects...", file=sys.stderr)
        projects = find_rescript_projects(project_root)
        print(f"Found {len(projects)} project(s)", file=sys.stderr)
        if not projects:
            raise RuntimeError(f"No ReScript packages found in {project_root}")

        # Resolve dependencies
        print("Resolving dependencies...", file=sys.stderr)
        package_map: dict[str, dict] = {}

        runtime_pkg = resolve_package("@rescript/runtime", project_root)
        if runtime_pkg:
            package_map["@rescript/runtime"] = runtime_pkg

        for project in projects:
            package_map[project["name"]] = project
            for dep in project["dependencies"]:
                if dep not in package_map:
                    resolved = resolve_package(dep, project_root)
                    if resolved:
                        package_map[dep] = resolved

        print(f"Total packages to index: {len(package_map)}", file=sys.stderr)

        # Resolve runtime path for RESCRIPT_RUNTIME env var
        runtime_path = get_runtime_path(project_root)

        files_processed = 0
        files_skipped = 0

        for pkg_name, pkg in package_map.items():
            print(f"Processing package: {pkg_name}", file=sys.stderr)

            config_hash = get_package_config_hash(pkg["path"])
            cur.execute(
                "INSERT INTO packages (name, path, rescript_json, config_hash) "
                "VALUES (?, ?, ?, ?) "
                "ON CONFLICT(name) DO UPDATE SET "
                "path = excluded.path, rescript_json = excluded.rescript_json, "
                "config_hash = excluded.config_hash "
                "RETURNING id",
                (
                    pkg["name"],
                    pkg["path"],
                    json.dumps(pkg.get("rescriptJson", {})),
                    config_hash,
                ),
            )
            package_id = cur.fetchone()[0]
            conn.commit()

            res_files = get_rescript_files(pkg["path"])
            print(f"  Found {len(res_files)} ReScript file(s)", file=sys.stderr)

            doc_env = None
            if pkg_name == "@rescript/runtime" and runtime_path:
                doc_env = {"RESCRIPT_RUNTIME": runtime_path}

            # Phase 1: Hash check — identify files that need processing
            files_to_process = []
            for res_file in res_files:
                cur.execute(
                    "SELECT id, qualified_name, file_hash FROM modules WHERE compiled_file_path = ?",
                    (res_file,),
                )
                existing = cur.fetchall()

                cmi_path = re.sub(r"\.resi?$", ".cmi", res_file)
                cmi_hash = hash_file(cmi_path)

                needs_processing = len(existing) == 0
                if not needs_processing and cmi_hash:
                    needs_processing = any(row[2] != cmi_hash for row in existing)

                if not needs_processing:
                    files_skipped += len(existing) or 1
                    continue

                files_to_process.append((res_file, cmi_hash))

            if files_to_process:
                print(
                    f"  Processing {len(files_to_process)} changed file(s)...",
                    file=sys.stderr,
                )

                # Phase 2: Extract documentation in parallel
                doc_results = extract_documentation_batch(
                    [f for f, _ in files_to_process], pkg["path"], doc_env
                )

                # Phase 3: Sequential database writes
                for res_file, cmi_hash in files_to_process:
                    modules = doc_results.get(res_file, [])
                    source_file_path = find_source_file(res_file, pkg["path"])

                    for module in modules:
                        cur.execute(
                            "SELECT id, file_hash FROM modules WHERE qualified_name = ?",
                            (module["qualifiedName"],),
                        )
                        existing_module = cur.fetchone()

                        files_processed += 1

                        if existing_module:
                            cur.execute(
                                'DELETE FROM "values" WHERE module_id = ?',
                                (existing_module[0],),
                            )
                            cur.execute(
                                "DELETE FROM types WHERE module_id = ?",
                                (existing_module[0],),
                            )

                        insert_module_recursive(
                            cur,
                            module,
                            package_id,
                            None,
                            res_file,
                            cmi_hash,
                            source_file_path,
                        )

                conn.commit()

            detect_and_mark_auto_opened(cur, pkg, package_id)
            conn.commit()

        # Stats
        cur.execute("SELECT COUNT(*) FROM packages")
        pkg_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM modules")
        mod_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM types")
        type_count = cur.fetchone()[0]
        cur.execute('SELECT COUNT(*) FROM "values"')
        val_count = cur.fetchone()[0]

        duration = time.monotonic() - start_time

        print("\nSync completed successfully!", file=sys.stderr)
        print(f"  Duration: {duration:.2f}s", file=sys.stderr)
        print(f"  Packages: {pkg_count}", file=sys.stderr)
        print(
            f"  Modules: {mod_count} ({files_processed} processed, {files_skipped} skipped)",
            file=sys.stderr,
        )
        print(f"  Types: {type_count}", file=sys.stderr)
        print(f"  Values: {val_count}", file=sys.stderr)

        print(
            json.dumps(
                {
                    "success": True,
                    "stats": {
                        "packages": pkg_count,
                        "modules": mod_count,
                        "types": type_count,
                        "values": val_count,
                    },
                    "duration": round(duration, 2),
                }
            )
        )
    finally:
        conn.close()


# =============================================================================
# Update Command (incremental, for js-post-build)
# =============================================================================


def update_module(project_root: str, js_output_path: str):
    file_name = os.path.basename(js_output_path)
    module_name = file_name.split(".")[0]

    if not module_name:
        print(
            f"Could not extract module name from: {js_output_path}",
            file=sys.stderr,
        )
        sys.exit(1)

    db_path = find_db_path(project_root)
    if not db_path:
        return

    ocaml_dir = os.path.join(project_root, "lib", "ocaml")
    cmi_path = os.path.join(ocaml_dir, f"{module_name}.cmi")
    cmi_hash = hash_file(cmi_path)

    if not cmi_hash:
        return

    # Do expensive work (rescript-tools doc) BEFORE touching the database
    resi_path = os.path.join(ocaml_dir, f"{module_name}.resi")
    if os.path.isfile(resi_path):
        doc_file_path = resi_path
    else:
        doc_file_path = os.path.join(ocaml_dir, f"{module_name}.res")

    modules = extract_documentation(doc_file_path, project_root)
    if not modules:
        return

    source_file_path = find_source_file(doc_file_path, project_root)

    # Open db with proper busy timeout for cross-process contention
    conn = sqlite3.connect(db_path, timeout=30)
    conn.execute("PRAGMA journal_mode=WAL")
    try:
        cur = conn.cursor()

        # Check if update is needed
        cur.execute(
            "SELECT id, file_hash FROM modules WHERE qualified_name = ?",
            (module_name,),
        )
        existing = cur.fetchone()

        if existing and existing[1] == cmi_hash:
            return

        cur.execute("SELECT id FROM packages WHERE path = ?", (project_root,))
        pkg = cur.fetchone()

        if not pkg:
            print(
                f"Package not found in db for path: {project_root}. Run 'sync' first.",
                file=sys.stderr,
            )
            return

        package_id = pkg[0]

        # Delete existing data for this module
        if existing:
            existing_id = existing[0]
            cur.execute(
                "SELECT id FROM modules WHERE parent_module_id = ?",
                (existing_id,),
            )
            nested_ids = [r[0] for r in cur.fetchall()]
            all_ids = [existing_id] + nested_ids

            for mid in all_ids:
                cur.execute('DELETE FROM "values" WHERE module_id = ?', (mid,))
                cur.execute("DELETE FROM types WHERE module_id = ?", (mid,))
                cur.execute("DELETE FROM aliases WHERE source_module_id = ?", (mid,))

            for mid in nested_ids:
                cur.execute("DELETE FROM modules WHERE id = ?", (mid,))
            cur.execute("DELETE FROM modules WHERE id = ?", (existing_id,))

        # Insert new data
        for module in modules:
            insert_module_recursive(
                cur,
                module,
                package_id,
                None,
                doc_file_path,
                cmi_hash,
                source_file_path,
            )

        conn.commit()
        print(f"Updated {module_name} ({len(modules)} module(s))", file=sys.stderr)
    finally:
        conn.close()


# =============================================================================
# Query Command
# =============================================================================

FORBIDDEN_SQL = [
    "INSERT",
    "UPDATE",
    "DELETE",
    "DROP",
    "ALTER",
    "CREATE",
    "TRUNCATE",
    "REPLACE",
]


def query_database(project_root: str, sql: str):
    db_path = get_db_path(project_root)
    if not os.path.isfile(db_path):
        raise RuntimeError(f"Database not found at {db_path}. Run 'sync' first.")

    sql_upper = sql.upper().strip()
    for keyword in FORBIDDEN_SQL:
        if keyword in sql_upper:
            raise RuntimeError(
                f"Forbidden SQL keyword: {keyword}. Only SELECT queries are allowed."
            )
    if not sql_upper.startswith("SELECT"):
        raise RuntimeError("Only SELECT queries are allowed.")

    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        cur = conn.execute(sql)
        rows = [dict(row) for row in cur.fetchall()]
        return rows
    finally:
        conn.close()


# =============================================================================
# CLI Entry Point
# =============================================================================


def main():
    args = sys.argv[1:]
    command = args[0] if args else None

    if command == "sync":
        project_root = args[1] if len(args) > 1 else os.getcwd()
        try:
            sync_database(project_root)
        except Exception as e:
            print(f"Sync failed: {e}", file=sys.stderr)
            print(json.dumps({"success": False, "error": str(e)}))
            sys.exit(1)

    elif command == "update":
        if len(args) < 2:
            print("Usage: rescript-db.py update <js-output-path>", file=sys.stderr)
            sys.exit(1)
        js_output_path = args[1]
        project_root = os.getcwd()
        try:
            update_module(project_root, js_output_path)
        except Exception as e:
            print(f"[js-post-build] Update failed: {e}", file=sys.stderr)
            sys.exit(1)

    elif command == "query":
        if len(args) < 2:
            print('Usage: rescript-db.py query "SELECT ..."', file=sys.stderr)
            sys.exit(1)
        sql = args[1]
        project_root = os.getcwd()
        try:
            results = query_database(project_root, sql)
            print(json.dumps(results, indent=2))
        except Exception as e:
            print(f"Query failed: {e}", file=sys.stderr)
            print(json.dumps({"error": str(e)}))
            sys.exit(1)

    else:
        print(
            """
ReScript Database CLI

Usage:
    uv run rescript-db.py sync [project_root]       Sync/create the database (defaults to cwd)
    uv run rescript-db.py update <js-output-path>   Incremental update for a single module (js-post-build)
    uv run rescript-db.py query "SELECT ..."        Run a SELECT query against the database

Examples:
    uv run rescript-db.py sync
    uv run rescript-db.py sync /path/to/project
    uv run rescript-db.py update lib/bs/src/App.res.jsx
    uv run rescript-db.py query "SELECT name FROM packages"
    uv run rescript-db.py query "SELECT name, signature FROM \\"values\\" WHERE name LIKE '%map%' LIMIT 10"
""".strip()
        )


if __name__ == "__main__":
    main()
