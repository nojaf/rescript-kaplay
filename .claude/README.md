# Context Overview

**Primary codebase**: `/Users/nojaf/Projects/rescript-kaplay` - ReScript bindings for Kaplay
**Reference only**: `/Users/nojaf/Projects/kaplay` - Installed Kaplay source (v4000.0.0-alpha.25)

## Files

- `rescript-guidelines.md` - ReScript v12 patterns, syntax, external bindings
- `kaplay-bindings.md` - Kaplay binding usage, component patterns, common pitfalls
- `kaplay-shaders.md` - Shader loading, uniform types, examples
- `kaplay-rule-system.md` - RuleSystem AI patterns, fact decomposition, salience
- `skirmish-game-design.md` - Game design, AI implementation, testing approach

## Key Info

- Package: `@nojaf/rescript-kaplay` under `Kaplay` namespace
- ReScript v12 rc, no Belt/Js modules, use dict{} pattern matching
- Bindings use @send, @new, @module patterns
- Never run rescript build (user runs `bunx rescript watch`)
