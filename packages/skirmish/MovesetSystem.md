# Moveset System Architecture

## Overview

This document describes the remaining work for implementing a moveset system where Pokemon can have 1-4 moves, each with PP tracking, cooldowns, keybindings, and AI integration.

## What's Already Implemented

### Core Infrastructure (Complete)

- `PkmnMove.res` - Move type definitions with abstract `pkmn` type
  - `canCast(slot, currentTime)` - checks PP > 0, not ZeroMove, and cooldown elapsed
  - `defaultAddRulesForAI` - generic AI availability rules for all moves
  - `move0Facts` through `move3Facts` - fact names for each move slot
- `ZeroMove.res` - No-op move for empty slots
- `Pokemon.res` updates:
  - `attackStatus` variant: `CannotAttack | CanAttack(array<int>)`
  - Move slots in type `t` (`moveSlot1` through `moveSlot4`)
  - `make()` accepts optional `~move1`, `~move2`, etc. parameters (default to ZeroMove)
  - `getMoveSlot(pokemon, index)` helper returns `option<PkmnMove.moveSlot>`
  - `finishAttack(k, pokemon)` recalculates available moves based on PP and cooldown
  - `scheduleFinishAttack(k, pokemon, cooldown)` - internal helper for cooldown scheduling
  - `canAttack(pokemon)` checks if pokemon can attack
  - `tryCastMove(k, pokemon, moveIndex)` handles attack execution:
    - Decrements PP
    - Records `lastUsedAt`
    - Sets `attackStatus` to `CannotAttack`
    - Calls move's `cast` function
    - Automatically schedules `finishAttack` after `coolDownDuration`
  - `getAvailableMoveIndices(slots, currentTime)` helper using `PkmnMove.canCast`
  - `fromAbstractPkmn` / `toAbstractPkmn` conversion functions

### Move Updates (Complete)

- `Ember.res` - Has `move: PkmnMove.t` with `coolDownDuration` and move-specific AI rules
- `Thundershock.res` - Has `move: PkmnMove.t` with `coolDownDuration`
- `QuickAttack.res` - Has `move: PkmnMove.t` with `coolDownDuration`
- Moves no longer need to call `finishAttack` - handled automatically by `tryCastMove`

### Player Integration (Complete)

- `Player.res` now takes `Pokemon.t` as argument (doesn't construct it)
- `KeyEdge` module for edge detection of key presses
- Uses vim-style home row keys: j/k/l/; for moves 0-3
- Calls `Pokemon.tryCastMove(k, pokemon, moveIndex)` based on key pressed

### PP Tracking (Complete)

- `Pokemon.tryCastMove()` decrements PP and records `lastUsedAt`
- `PkmnMove.canCast()` checks PP > 0 before allowing cast
- `Pokemon.make()` uses `getAvailableMoveIndices` for initial `attackStatus`

### Cooldown Tracking (Complete)

- `PkmnMove.canCast(slot, currentTime)` checks:
  - PP remaining > 0
  - Not a ZeroMove (id != -1)
  - Cooldown elapsed: `currentTime - lastUsedAt >= coolDownDuration`
- `Pokemon.finishAttack(k, pokemon)` uses current time to check cooldowns
- `Pokemon.tryCastMove()` automatically schedules `finishAttack` after move's `coolDownDuration`
- Moves define their own `coolDownDuration` in the `PkmnMove.t` record

### Healthbar UI (Complete)

- `Healthbar.res` stores pokemon reference in state
- Player healthbar shows moves in 2x2 grid (left 70%) with name/HP section (right 30%)
- Each move cell displays:
  - Hotkey label (J/K/L/;) on left
  - PP fraction (current/max) on right
  - Move name centered below
- Empty slots show "(key) ---" in gray
- Alternating background colors for move cells
- PP shown in red when depleted
- **Cooldown overlay**: gray rectangle that shrinks left-to-right as cooldown progresses
- Debug rectangles controlled by `k.debug.inspect`

### Layout System (Complete)

- `Healthbar.Layout` module with configurable constants for player healthbar:
  - Move grid: padding, gap, cell dimensions, font sizes
  - Cell backgrounds: light/dark alternating colors, cooldown overlay color
  - Section ratios: moves (70%) / nameHP (30%)
  - Name/HP section: font sizes, spacing, HP bar dimensions
- `Healthbar.OpponentLayout` module for opponent healthbar:
  - Positioning for name, level, HP bar
  - Font sizes and dimensions
- `Wall.res` uses Layout heights for play area calculation

### EnemyAI Integration (Complete)

- Modular architecture in `src/EnemyAI/` folder:
  - `AIFacts.res` - Central registry of all fact names (breaks circular dependencies)
  - `RuleSystemState.res` - State type for the rule system
  - `BaseFacts.res` - Computes base facts from game state (attack positions, space, player position)
  - `DerivedFacts.res` - Computes threat levels from base facts
  - `DefensiveFacts.res` - Computes dodge decisions and movement
  - `MoveFacts.res` - Handles move availability and selection
- `EnemyAI.res` - Main entry point, re-exports modules
- `EnemyAI.make(k, ~enemy, ~player)` - Attaches AI behavior to an existing Pokemon
- Move-specific AI rules via `addRulesForAI` in each move:
  - `PkmnMove.defaultAddRulesForAI` - Generic availability check (PP > 0, cooldown elapsed)
  - Moves can add custom rules (e.g., Ember asserts `shouldAttack` when not under threat)
- `MoveFacts.selectMove(rs)` - Returns first available move index
- Dynamic move selection replaces hardcoded `tryCastMove(k, enemy, 0)`

---

## Remaining Work

### Phase 1: Testing & Polish

- [ ] Test player move casting with all 4 keys
- [ ] Test PP depletion and move unavailability
- [ ] Test cooldown system per move
- [ ] Test AI move selection
- [ ] Test ZeroMove slots (empty slots)
- [ ] Test healthbar display updates

---

## Key Design Decisions Made

1. **Move slots are immutable** - Set at Pokemon creation, not changed at runtime
2. **`attackStatus` tracks available move indices** - `CanAttack([0, 1, 2, 3])` means all 4 moves available
3. **Cooldown handled automatically** - `tryCastMove` schedules `finishAttack` using the move's `coolDownDuration`
4. **`Player.make` takes a Pokemon** - Doesn't create the Pokemon, just adds input handling
5. **`EnemyAI.make` takes a Pokemon** - Doesn't create the Pokemon, just adds AI behavior
6. **Abstract `pkmn` type in PkmnMove.res** - Breaks circular dependency with Pokemon.res
7. **ZeroMove uses id = -1** - Reserved for empty slots
8. **Vim-style keybindings** - j/k/l/; for moves 0-3 (home row, right hand)
9. **Layout modules for UI** - All hardcoded values extracted to `Layout` and `OpponentLayout` modules for easy tweaking
10. **Cooldown UI feedback** - Visual overlay on move cells shows cooldown progress
11. **AIFacts as central registry** - All fact names in one place, accessible to both EnemyAI modules and individual moves
12. **Move-specific AI rules** - Each move can define custom `addRulesForAI` for attack conditions (e.g., Ember attacks when safe)

---

## Potential Blockers & Considerations

### 1. **Mobility vs Attack Status**

Some moves block movement (`mobility = CannotMove`), others don't. These are independent:

- `mobility`: Can the Pokemon move?
- `attackStatus`: Can the Pokemon attack?

Thundershock sets both, Ember only sets attackStatus.

### 2. **PP Restoration**

Currently PP is only set at Pokemon creation. Restoration is out of scope for now.

---

## Future Enhancements (Out of Scope)

1. Move Types (Fire, Electric, Normal, etc.)
2. Accuracy as a stat
3. Status Effects (burn, paralyze, etc.)
4. Move Priority
5. PP Restoration items/mechanics
6. Move Learning system
7. Move Categories (Physical, Special, Status)
8. Critical Hits
9. Type Effectiveness
