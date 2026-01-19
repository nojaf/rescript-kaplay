# Moveset System Architecture

## Overview

This document describes the remaining work for implementing a moveset system where Pokemon can have 1-4 moves, each with PP tracking, cooldowns, keybindings, and AI integration.

## What's Already Implemented

### Core Infrastructure (✅ Complete)

- `PkmnMove.res` - Move type definitions with abstract `pkmn` type
- `ZeroMove.res` - No-op move for empty slots
- `Pokemon.res` updates:
  - `attackStatus` variant: `CannotAttack | CanAttack(array<int>)`
  - Move slots in type `t` (`moveSlot1` through `moveSlot4`)
  - `make()` accepts optional `~moveSlot1`, `~moveSlot2`, etc. parameters (default to ZeroMove)
  - `getMoveSlot(pokemon, index)` helper returns `option<PkmnMove.moveSlot>`
  - `finishAttack(pokemon)` recalculates available moves
  - `canAttack(pokemon)` checks if pokemon can attack
  - `tryCastMove(k, pokemon, moveIndex)` handles attack execution
  - `fromAbstractPkmn` / `toAbstractPkmn` conversion functions

### Move Updates (✅ Complete)

- `Ember.res` - Has `move: PkmnMove.t` and `moveSlot()` function
- `Thundershock.res` - Has `move: PkmnMove.t` and `moveSlot()` function
- `QuickAttack.res` - Has `move: PkmnMove.t` and `moveSlot()` function
- All moves call `Pokemon.finishAttack` after cooldown instead of directly setting `attackStatus`

### Player Integration (✅ Partial)

- `Player.res` now takes `Pokemon.t` as argument (doesn't construct it)
- Uses `Pokemon.tryCastMove(k, pokemon, 0)` for attacking
- `Game.res` creates Pokemon with move slots and passes to Player

### EnemyAI Integration (✅ Partial)

- Uses `Pokemon.canAttack()` for checking attack ability
- Uses `Pokemon.tryCastMove(k, enemy, 0)` for executing attacks

---

## Remaining Work

### Phase 1: Player Input for Multiple Moves

- [ ] Update `Player.res`:
  - [ ] Add key binding constants (j/k/l/; keys)
  - [ ] Add key press tracking for all 4 move keys
  - [ ] Replace single spacebar attack with move key handling
  - [ ] Call `tryCastMove` with appropriate index based on key pressed

### Phase 2: UI Updates

- [ ] Update `Healthbar.res`:
  - [ ] Store pokemon reference in healthbar state
  - [ ] Implement `drawMoves()` function
  - [ ] Display move names, PP, and key bindings
  - [ ] Only show for player team
  - [ ] Skip ZeroMove slots (id == -1)

### Phase 3: PP and Cooldown Tracking

- [ ] Update `Pokemon.tryCastMove()`:
  - [ ] Decrement PP when move is cast
  - [ ] Record `lastUsedAt` time
- [ ] Update `Pokemon.finishAttack()`:
  - [ ] Check PP and cooldowns for each move slot
  - [ ] Only include moves with PP > 0 and cooldown elapsed in `CanAttack` array
- [ ] Add helper in `PkmnMove.res`:
  - [ ] `canCast(moveSlot, currentTime)` - checks PP and cooldown

### Phase 4: AI Move Selection

- [ ] Update `EnemyAI.res`:
  - [ ] Implement `addRulesForAI` in each move for move-specific AI logic
  - [ ] Add move rules to rule system (query each move's availability/score)
  - [ ] Implement `selectBestMove()` function
  - [ ] Replace hardcoded `tryCastMove(k, enemy, 0)` with intelligent move selection

### Phase 5: Testing & Polish

- [ ] Test player move casting with all 4 keys
- [ ] Test PP depletion and move unavailability
- [ ] Test cooldown system per move
- [ ] Test AI move selection
- [ ] Test ZeroMove slots (empty slots)
- [ ] Test healthbar display

---

## Key Design Decisions Made

1. **Move slots are immutable** - Set at Pokemon creation, not changed at runtime
2. **`attackStatus` tracks available move indices** - `CanAttack([0, 1, 2, 3])` means all 4 moves available
3. **Moves don't set `attackStatus` directly** - They call `Pokemon.finishAttack()` after cooldown
4. **`Player.make` takes a Pokemon** - Doesn't create the Pokemon, just adds input handling
5. **Abstract `pkmn` type in PkmnMove.res** - Breaks circular dependency with Pokemon.res
6. **ZeroMove uses id = -1** - Reserved for empty slots

---

## Potential Blockers & Considerations

### 1. **Mobility vs Attack Status**

Some moves block movement (`mobility = CannotMove`), others don't. These are independent:

- `mobility`: Can the Pokemon move?
- `attackStatus`: Can the Pokemon attack?

Thundershock sets both, Ember only sets attackStatus.

### 2. **Cooldown Timing**

Each move has its own cooldown. After a move finishes, `finishAttack()` recalculates which moves are available based on individual cooldowns.

### 3. **Healthbar Pokemon Reference**

Healthbar needs access to Pokemon to display moves. Currently it only stores metadata. Needs to store pokemon reference.

### 4. **PP Restoration**

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
