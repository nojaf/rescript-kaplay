# Agent Guidelines

## Build Commands

- Always use `bun` instead of `npm` or `npx` for package management and script running. Use `bunx` for one-off package execution.
- For ReScript compilation, use `bunx rescript` in the package directory (e.g., `packages/skirmish`) or on the root (to build all packages)
- To run tests, use `bunx vitest run` in the package directory
- The vite dev server is typically already running, so avoid running `vite build` for quick iterations

## Project Structure

- `packages/skirmish` - Main game package
- `packages/rescript-kaplay` - ReScript bindings for Kaplay

## LSP Diagnostics Verification

The user may have an experimental ReScript LSP server running that exposes compiler diagnostics over HTTP. When active, the workflow has two distinct phases:

- **Editing a file** (buffer change) triggers type checking. The LSP server will update its diagnostics based on the new file contents. Query the diagnostics endpoint to see any errors or warnings.
- **Saving a file** triggers compilation and produces the output `.res.mjs` JavaScript file. Read the compiled `.res.mjs` file to confirm the generated JavaScript matches expectations.

To query the diagnostics endpoint, run: `curl -s http://127.0.0.1:12303/diagnostics | jq .`.
If the server is not running, you won't get a OK response.

The endpoint blocks while a build is in progress and only responds once it's complete, so there is no need to add a sleep delay before querying — the response always reflects the latest state.

Use the diagnostics endpoint in two ways: either the user asks you to fix a reported diagnostic (query first to understand the problem, fix it, query again to confirm), or as a verification step after any edit to ensure you haven't introduced new issues.

## ReScript Conventions

- Interface files (`.resi`) must be kept in sync with implementation files (`.res`)
- When adding optional parameters to a function, update both the `.res` and `.resi` files
- In `switch` or `if/else` expressions, put the shortest branch first (unless impossible due to wildcard patterns)
