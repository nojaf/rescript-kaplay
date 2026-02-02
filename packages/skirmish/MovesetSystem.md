# Moveset System Architecture

## Overview

This document describes the remaining work for implementing a moveset system where Pokemon can have 1-4 moves, each with PP tracking, cooldowns, keybindings, and AI integration.

## What's Already Implemented

### Core Infrastructure (Complete)

- `PkmnMove.res` - Move type definitions with abstract `pkmn` type
  - `canCast(slot, currentTime)` - checks PP > 0, not ZeroMove, and cooldown elapsed
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

- `Ember.res` - Has `move: PkmnMove.t` with `coolDownDuration`
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

### EnemyAI Integration (Partial)

- Uses `Pokemon.canAttack()` for checking attack ability
- Uses `Pokemon.tryCastMove(k, enemy, 0)` for executing attacks (hardcoded to move 0)

---

## Remaining Work

### Phase 1: AI Move Selection

- [ ] Update `EnemyAI.res`:
  - [ ] Implement `addRulesForAI` in each move for move-specific AI logic
  - [ ] Add move rules to rule system (query each move's availability/score)
  - [ ] Implement `selectBestMove()` function
  - [ ] Replace hardcoded `tryCastMove(k, enemy, 0)` with intelligent move selection

### Phase 2: Testing & Polish

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
5. **Abstract `pkmn` type in PkmnMove.res** - Breaks circular dependency with Pokemon.res
6. **ZeroMove uses id = -1** - Reserved for empty slots
7. **Vim-style keybindings** - j/k/l/; for moves 0-3 (home row, right hand)
8. **Layout modules for UI** - All hardcoded values extracted to `Layout` and `OpponentLayout` modules for easy tweaking
9. **Cooldown UI feedback** - Visual overlay on move cells shows cooldown progress

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
