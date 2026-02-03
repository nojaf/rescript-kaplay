# Agent Guidelines

## Build Commands

- Use `bun` instead of `npm` for running scripts
- For ReScript compilation, use `bunx rescript` in the package directory (e.g., `packages/skirmish`) or on the root (to build all packages)
- To run tests, use `bunx vitest run` in the package directory
- The vite dev server is typically already running, so avoid running `vite build` for quick iterations

## Project Structure

- `packages/skirmish` - Main game package
- `packages/rescript-kaplay` - ReScript bindings for Kaplay

## ReScript Conventions

- Interface files (`.resi`) must be kept in sync with implementation files (`.res`)
- When adding optional parameters to a function, update both the `.res` and `.resi` files
- In `switch` or `if/else` expressions, put the shortest branch first (unless impossible due to wildcard patterns)
