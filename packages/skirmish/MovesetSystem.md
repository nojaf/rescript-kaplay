# Moveset System Architecture

## Overview
This document describes the architecture for implementing a moveset system where Pokemon can have 1-4 moves, each with PP tracking, cooldowns, keybindings, and AI integration.

## Goals
- Pokemon can have 1-4 moves (min 1, max 4)
- Each move tracks its own PP (Power Points) and cooldown independently
- Player uses j/k/l/; keys to trigger moves
- Healthbar displays available moves with PP counts for player Pokemon
- Enemy AI integrates move selection through the rule system
- Move-specific AI logic is encapsulated within each move module

---

## Core Type System

### Move.res (New Shared Module)

This module defines the shared move interface and utility functions.

**Note on Circular Dependencies:** To avoid circular dependencies between `Pokemon.res`, `Move.res`, and `EnemyAIRuleSystemState.res`, we use **abstract types** for `pokemon` and `aiState`. These are placeholder types that get cast to/from concrete types at the boundaries using `%identity` externals. While this requires explicit casting in move implementations, it provides compile-time guarantees that all moves implement required functions without creating module cycles.

```rescript
// Abstract types to break circular dependencies
type pokemon  // Represents Pokemon.t without depending on Pokemon.res
type aiState  // Represents EnemyAIRuleSystemState.t without depending on EnemyAIRuleSystemState.res

// Move slot combines move definition and its runtime state
// Consolidated to avoid unnecessary nesting
type moveSlot = {
  move: t,
  mutable currentPP: int,
  mutable lastUsedAt: float,
}

// The move definition type (singleton instance per move type)
and t = {
  id: int,  // Unique identifier (manually assigned per move)
  name: string,
  maxPP: int,
  baseDamage: int,
  coolDownDuration: float,
  
  // Execute the move
  // Uses abstract pokemon type to avoid circular dependency
  cast: (Context.t, pokemon) => unit,
  
  // Add AI rules for this move to the rule system
  // prefix: e.g., "move-1", "move-2" - used to namespace facts
  // moveSlot: contains move and current state (PP, last used time)
  // ruleSystemState: full game state for AI evaluation (abstract type)
  addRulesForAI: (
    RuleSystem.t<aiState>,
    ~prefix: string,
    ~moveSlot: moveSlot,
    ~ruleSystemState: aiState,
    ~moveFactNames: moveFactNames,
  ) => unit,
}

// Standard fact names that EnemyAI expects moves to produce
type moveFactNames = {
  available: string,      // e.g., "move-1-available"
  successRate: string,    // e.g., "move-1-success-rate"
  // Add more as needed
}

// === Conversion Functions (Breaking Circular Dependencies) ===

// Convert concrete types to abstract types (used in Pokemon.res, EnemyAI.res)
external pokemonToAbstract: Pokemon.t => pokemon = "%identity"
external aiStateToAbstract: EnemyAIRuleSystemState.t => aiState = "%identity"

// Convert abstract types to concrete types (used in move implementations)
external pokemonFromAbstract: pokemon => Pokemon.t = "%identity"
external aiStateFromAbstract: aiState => EnemyAIRuleSystemState.t = "%identity"

// === Helper Functions ===

let canCast = (moveSlot: moveSlot, currentTime: float): bool => {
  moveSlot.currentPP > 0 && 
  currentTime - moveSlot.lastUsedAt >= moveSlot.move.coolDownDuration
}

let decrementPP = (moveSlot: moveSlot): unit => {
  moveSlot.currentPP = max(0, moveSlot.currentPP - 1)
}

let recordUsage = (moveSlot: moveSlot, currentTime: float): unit => {
  moveSlot.lastUsedAt = currentTime
}

let createMoveFactNames = (~prefix: string): moveFactNames => {
  available: `${prefix}-available`,
  successRate: `${prefix}-success-rate`,
}

// Reserved ID for no-op move
let noMoveId = 0
```

---

## Pokemon Changes

### Updated Pokemon.res Type

```rescript
// Updated attack status variant to track which moves are available
type attackStatus = 
  | CannotAttack  // Currently executing a move
  | CanAttack(array<int>)  // Array of move indices (0-3) that are available

type t = {
  // ... existing fields (direction, facing, level, pokemonId, team, etc.)
  mutable attackStatus: attackStatus,
  
  // Four move slots (always present, use NoMove for empty slots)
  // Note: moveSlot is defined in Move.res and contains move + mutable state
  moveSlot1: Move.moveSlot,
  moveSlot2: Move.moveSlot,
  moveSlot3: Move.moveSlot,
  moveSlot4: Move.moveSlot,
}
```

### Updated Pokemon Constructor

```rescript
let make = (
  k: Context.t,
  ~pokemonId: int,
  ~level: int,
  ~team: Team.t,
  ~moves: array<Move.t>,  // 1-4 moves provided
): t => {
  // Fill slots: use provided moves, pad with NoMove
  let move1 = moves->Array.get(0)->Option.getOr(NoMove.move)
  let move2 = moves->Array.get(1)->Option.getOr(NoMove.move)
  let move3 = moves->Array.get(2)->Option.getOr(NoMove.move)
  let move4 = moves->Array.get(3)->Option.getOr(NoMove.move)
  
  // Initialize move slots with state
  let createMoveSlot = (move: Move.t): Move.moveSlot => {
    move,
    currentPP: move.maxPP,
    lastUsedAt: -infinity,  // Never used
  }
  
  let gameObj: t = k->Context.add([
    internalState({
      // ... existing fields
      attackStatus: CanAttack([0, 1, 2, 3]),  // Initially all slots available
      moveSlot1: createMoveSlot(move1),
      moveSlot2: createMoveSlot(move2),
      moveSlot3: createMoveSlot(move3),
      moveSlot4: createMoveSlot(move4),
    }),
    // ... rest of components
  ])
  
  gameObj
}
```

### Helper Functions in Pokemon.res

```rescript
// Get move slot by index (0-3)
let getMoveSlot = (pokemon: t, index: int): Move.moveSlot => {
  switch index {
  | 0 => pokemon.moveSlot1
  | 1 => pokemon.moveSlot2
  | 2 => pokemon.moveSlot3
  | 3 => pokemon.moveSlot4
  | _ => Js.Exn.raiseError("Invalid move index")
  }
}

// Called when a move finishes execution
// Recalculates which moves are available based on PP and cooldowns
let onMoveFinished = (pokemon: t, k: Context.t): unit => {
  let currentTime = k->Context.time
  
  let availableMoves = [0, 1, 2, 3]->Array.filter(idx => {
    let slot = getMoveSlot(pokemon, idx)
    Move.canCast(slot, currentTime)
  })
  
  pokemon.attackStatus = CanAttack(availableMoves)
}

// Attempt to cast a move by index
// Returns true if cast was successful
let tryCastMove = (pokemon: t, k: Context.t, moveIndex: int): bool => {
  switch pokemon.attackStatus {
  | CannotAttack => false
  | CanAttack(availableMoves) => {
      if availableMoves->Array.includes(moveIndex) {
        let slot = getMoveSlot(pokemon, moveIndex)
        let currentTime = k->Context.time
        
        if Move.canCast(slot, currentTime) {
          // Mark as attacking (blocks all moves)
          pokemon.attackStatus = CannotAttack
          
          // Record usage
          Move.decrementPP(slot)
          Move.recordUsage(slot, currentTime)
          
          // Execute the move (convert pokemon to abstract type)
          slot.move.cast(k, pokemon->Move.pokemonToAbstract)
          
          true
        } else {
          false
        }
      } else {
        false
      }
    }
  }
}
```

---

## NoMove Implementation

### NoMove.res (New File)

```rescript
// No-op move for unused slots

let move: Move.t = {
  id: 0,  // Reserved ID for no-op
  name: "---",
  maxPP: 0,
  baseDamage: 0,
  coolDownDuration: 0.,
  cast: (_k, _pokemon) => {
    // No-op
  },
  addRulesForAI: (_rs, ~prefix, ~moveState as _, ~ruleSystemState as _, ~moveFactNames) => {
    // Assert that this move is never available
    // This ensures AI never selects empty move slots
    // We can add rules with very low scores or simply not assert availability
  },
}
```

---

## Concrete Move Updates

### Example: Ember.res

Each move module keeps its existing implementation but adds a `Move.t` instance.

```rescript
open Kaplay

// ... existing type t, includes, spriteName, load(), etc.

let coolDown = 1.

// Move definition instance
let move: Move.t = {
  id: 1,  // Unique ID for Ember
  name: "Ember",
  maxPP: 25,
  baseDamage: 5,
  coolDownDuration: coolDown,
  
  cast: (k, pokemonAbstract) => {
    // Convert abstract pokemon type to concrete Pokemon.t
    let pokemon = pokemonAbstract->Move.pokemonFromAbstract
    
    // ... existing flame spawning logic
    
    pokemon.attackStatus = Attacking  // Will be replaced with CannotAttack
    
    // ... collision handlers, etc.
    
    k->Context.wait(coolDown, () => {
      // Instead of: pokemon.attackStatus = CanAttack
      // Call: pokemon->Pokemon.onMoveFinished(k)
    })
  },
  
  addRulesForAI: (rs, ~prefix, ~moveSlot, ~ruleSystemState, ~moveFactNames) => {
    // Convert abstract AI state to concrete type
    let state = ruleSystemState->Move.aiStateFromAbstract
    
    open RuleSystem
    
    let currentTime = state.enemy->Pokemon.getContext->Context.time
    let canCast = Move.canCast(moveSlot, currentTime)
    
    if canCast {
      // Assert that this move is available
      rs->assertFact(Fact(moveFactNames.available), Salience(100.0))
      
      // Calculate success rate based on positioning, range, etc.
      // This is move-specific logic
      let playerPos = state.player->Pokemon.worldPos
      let enemyPos = state.enemy->Pokemon.worldPos
      let distance = playerPos->Vec2.World.dist(enemyPos)
      
      // Ember is a projectile - more effective at medium range
      let score = if distance > 50. && distance < 200. {
        0.8  // Good range
      } else if distance <= 50. {
        0.5  // Too close, might miss
      } else {
        0.3  // Too far
      }
      
      rs->assertFact(Fact(moveFactNames.successRate), Salience(score))
    }
  },
}
```

### Example: Thundershock.res

```rescript
// Similar structure to Ember

let move: Move.t = {
  id: 2,
  name: "Thundershock",
  maxPP: 15,
  baseDamage: 5,
  coolDownDuration: 1.,
  
  cast: (k, pokemonAbstract) => {
    // Convert abstract pokemon type to concrete Pokemon.t
    let pokemon = pokemonAbstract->Move.pokemonFromAbstract
    
    // ... existing Thundershock implementation
  },
  
  addRulesForAI: (rs, ~prefix, ~moveSlot, ~ruleSystemState, ~moveFactNames) => {
    // Convert abstract AI state to concrete type
    let state = ruleSystemState->Move.aiStateFromAbstract
    
    // Thundershock-specific AI logic
    // - Only works in vertical directions
    // - Blocks movement during execution
    // - Good when player is directly above/below
    
    let currentTime = state.enemy->Pokemon.getContext->Context.time
    let canCast = Move.canCast(moveSlot, currentTime)
    if canCast {
      rs->assertFact(Fact(moveFactNames.available), Salience(100.0))
      
      // Calculate score based on alignment
      let playerPos = state.player->Pokemon.worldPos
      let enemyPos = state.enemy->Pokemon.worldPos
      let horizontalDist = abs_float(playerPos.x - enemyPos.x)
      
      let score = if horizontalDist < 20. {
        0.9  // Well aligned
      } else if horizontalDist < 50. {
        0.6  // Somewhat aligned
      } else {
        0.2  // Poorly aligned
      }
      
      rs->assertFact(Fact(moveFactNames.successRate), Salience(score))
    }
  },
}
```

### Example: QuickAttack.res

```rescript
let move: Move.t = {
  id: 3,
  name: "Quick Attack",
  maxPP: 30,
  baseDamage: 3,
  coolDownDuration: 0.4,
  
  cast: (k, pokemonAbstract) => {
    // Convert abstract pokemon type to concrete Pokemon.t
    let pokemon = pokemonAbstract->Move.pokemonFromAbstract
    
    // ... existing QuickAttack implementation
  },
  
  addRulesForAI: (rs, ~prefix, ~moveSlot, ~ruleSystemState, ~moveFactNames) => {
    // Convert abstract AI state to concrete type
    let state = ruleSystemState->Move.aiStateFromAbstract
    
    // QuickAttack-specific AI logic
    // - Fast cooldown, good for aggressive play
    // - Melee range, needs to be close
    // - Has knockback, good for creating space
    
    let currentTime = state.enemy->Pokemon.getContext->Context.time
    let canCast = Move.canCast(moveSlot, currentTime)
    if canCast {
      rs->assertFact(Fact(moveFactNames.available), Salience(100.0))
      
      let playerPos = state.player->Pokemon.worldPos
      let enemyPos = state.enemy->Pokemon.worldPos
      let distance = playerPos->Vec2.World.dist(enemyPos)
      
      let score = if distance < 50. {
        0.85  // Very close - perfect for quick attack
      } else if distance < 100. {
        0.5   // Medium range - can close the gap
      } else {
        0.2   // Too far
      }
      
      rs->assertFact(Fact(moveFactNames.successRate), Salience(score))
    }
  },
}
```

---

## Player Integration

### Player.res Updates

```rescript
open Kaplay
open GameContext

// Key bindings (constants for reuse in Healthbar)
let move1Key = J
let move2Key = K
let move3Key = L
let move4Key = Semicolon

let make = (~pokemonId: int, ~level: int, ~moves: array<Move.t>): Pokemon.t => {
  let gameObj: Pokemon.t = Pokemon.make(k, ~pokemonId, ~level, ~team=Player, ~moves)

  // Track key states for each move key
  let move1WasDown = ref(false)
  let move2WasDown = ref(false)
  let move3WasDown = ref(false)
  let move4WasDown = ref(false)

  k->Context.onUpdate(() => {
    // Check move 1 (j key)
    let isMove1Pressed = k->Context.isKeyDown(move1Key)
    let isNewMove1Press = isMove1Pressed && !move1WasDown.contents
    move1WasDown.contents = isMove1Pressed
    
    // Check move 2 (k key)
    let isMove2Pressed = k->Context.isKeyDown(move2Key)
    let isNewMove2Press = isMove2Pressed && !move2WasDown.contents
    move2WasDown.contents = isMove2Pressed
    
    // Check move 3 (l key)
    let isMove3Pressed = k->Context.isKeyDown(move3Key)
    let isNewMove3Press = isMove3Pressed && !move3WasDown.contents
    move3WasDown.contents = isMove3Pressed
    
    // Check move 4 (; key)
    let isMove4Pressed = k->Context.isKeyDown(move4Key)
    let isNewMove4Press = isMove4Pressed && !move4WasDown.contents
    move4WasDown.contents = isMove4Pressed

    // Attempt to cast moves
    if isNewMove1Press {
      gameObj->Pokemon.tryCastMove(k, 0)->ignore
    } else if isNewMove2Press {
      gameObj->Pokemon.tryCastMove(k, 1)->ignore
    } else if isNewMove3Press {
      gameObj->Pokemon.tryCastMove(k, 2)->ignore
    } else if isNewMove4Press {
      gameObj->Pokemon.tryCastMove(k, 3)->ignore
    }

    // ... existing movement logic (WASD/arrows)
    let isUpPressed = k->Context.isKeyDown(Up) || k->Context.isKeyDown(W)
    let isDownPressed = k->Context.isKeyDown(Down) || k->Context.isKeyDown(S)
    let isLeftPressed = k->Context.isKeyDown(Left) || k->Context.isKeyDown(A)
    let isRightPressed = k->Context.isKeyDown(Right) || k->Context.isKeyDown(D)
    let movementPressed = isUpPressed || isDownPressed || isLeftPressed || isRightPressed

    if isUpPressed {
      gameObj.direction = k->Context.vec2Up
      gameObj->Pokemon.setSprite(Pokemon.backSpriteName(pokemonId))
    } else if isDownPressed {
      gameObj.direction = k->Context.vec2Down
      gameObj->Pokemon.setSprite(Pokemon.frontSpriteName(pokemonId))
    } else if isLeftPressed {
      gameObj.direction = k->Context.vec2Left
    } else if isRightPressed {
      gameObj.direction = k->Context.vec2Right
    }

    if gameObj.mobility == Pokemon.CanMove && movementPressed {
      gameObj->Pokemon.move(
        gameObj.direction->Vec2.Unit.asWorld->Vec2.World.scaleWith(Pokemon.movementSpeed),
      )
    }
  })

  gameObj
}
```

---

## Healthbar Integration

### Healthbar.res Updates

The healthbar needs to display moves for player Pokemon.

```rescript
// Add to the draw function for player healthbar

let drawMoves =
  @this
  (healthbar: t, pokemon: Pokemon.t) => {
    // Only draw moves for player team
    if healthbar.team != Team.Player {
      return ()
    }
    
    let startY = 42.  // Below existing healthbar
    let moveHeight = 12.
    
    // Array of (moveIndex, keyName) pairs
    let moves = [
      (0, "J"),
      (1, "K"),
      (2, "L"),
      (3, ";"),
    ]
    
    moves->Array.forEachWithIndex((idx, (moveIndex, keyName)) => {
      let slot = pokemon->Pokemon.getMoveSlot(moveIndex)
      
      // Skip NoMove (id == 0)
      if slot.move.id == 0 {
        return ()
      }
      
      let yPos = startY + (Float.fromInt(idx) * moveHeight)
      
      // Draw key binding
      k->Context.drawText({
        pos: k->Context.vec2Local(5., yPos),
        text: `[${keyName}]`,
        size: 8.,
        color: k->Color.black,
        font: PkmnFont.font,
      })
      
      // Draw move name
      k->Context.drawText({
        pos: k->Context.vec2Local(25., yPos),
        text: slot.move.name,
        size: 8.,
        color: k->Color.black,
        font: PkmnFont.font,
      })
      
      // Draw PP
      let ppText = `${Int.toString(slot.state.currentPP)}/${Int.toString(slot.move.maxPP)}`
      k->Context.drawText({
        pos: k->Context.vec2Local(90., yPos),
        text: ppText,
        size: 8.,
        color: k->Color.black,
        font: PkmnFont.font,
      })
    })
  }

// Update the main draw function to call drawMoves
let draw =
  @this
  (healthbar: t) => {
    // ... existing health bar drawing
    
    // Draw moves (only for player)
    // Note: Need to pass pokemon reference to healthbar
  }
```

**Note:** The healthbar will need a reference to the Pokemon to access move data. This can be passed during construction or stored in the healthbar state.

---

## Enemy AI Integration

### EnemyAI.res Updates

```rescript
// Update makeRuleSystem to add move rules

let makeRuleSystem = (state: ruleSystemState): RuleSystem.t => {
  let rs = RuleSystem.create()
  
  // Add existing rule modules
  BaseFacts.addRules(rs)
  DerivedFacts.addRules(rs)
  DefensiveFacts.addRules(rs)
  // ... etc.
  
  // Add rules for each move slot
  [0, 1, 2, 3]->Array.forEach(moveIndex => {
    let slot = state.enemy->Pokemon.getMoveSlot(moveIndex)
    let prefix = `move-${Int.toString(moveIndex + 1)}`
    let moveFactNames = Move.createMoveFactNames(~prefix)
    
    slot.move.addRulesForAI(
      rs,
      ~prefix,
      ~moveSlot=slot,
      ~ruleSystemState=state->Move.aiStateToAbstract,  // Convert to abstract type
      ~moveFactNames,
    )
  })
  
  rs
}

// Add move selection logic after rule system runs
let selectBestMove = (rs: RuleSystem.t, enemy: Pokemon.t, k: Context.t): option<int> => {
  // Query for available moves and their success rates
  let moveScores = [0, 1, 2, 3]->Array.map(moveIndex => {
    let prefix = `move-${Int.toString(moveIndex + 1)}`
    let moveFactNames = Move.createMoveFactNames(~prefix)
    
    let isAvailable = rs->RuleSystem.hasFact(Fact(moveFactNames.available))
    let successRate = if isAvailable {
      // Get the salience (score) of the success rate fact
      rs->RuleSystem.getFactSalience(Fact(moveFactNames.successRate))
        ->Option.getOr(0.0)
    } else {
      0.0
    }
    
    (moveIndex, successRate)
  })
  
  // Find move with highest score
  let bestMove = moveScores->Array.reduce(None, (best, (idx, score)) => {
    switch best {
    | None => if score > 0.0 { Some((idx, score)) } else { None }
    | Some((_, bestScore)) => {
        if score > bestScore {
          Some((idx, score))
        } else {
          best
        }
      }
    }
  })
  
  bestMove->Option.map(((idx, _score)) => idx)
}

// In the main AI update loop, after running rules:
let maybeExecuteMove = (state: ruleSystemState, k: Context.t): unit => {
  let rs = makeRuleSystem(state)
  RuleSystem.run(rs)
  
  // Check if we should attack (existing defensive logic passes)
  let shouldAttack = rs->RuleSystem.hasFact(SomeFact("should-attack"))
  
  if shouldAttack {
    switch selectBestMove(rs, state.enemy, k) {
    | Some(moveIndex) => {
        // Execute the selected move
        state.enemy->Pokemon.tryCastMove(k, moveIndex)->ignore
      }
    | None => {
        // No viable moves available
      }
    }
  }
}
```

---

## Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Create `Move.res` with type definitions and helper functions
- [ ] Create `NoMove.res` with no-op move implementation
- [ ] Update `Pokemon.res`:
  - [ ] Add `moveSlot` type
  - [ ] Update `attackStatus` variant
  - [ ] Update `t` type with 4 move slots
  - [ ] Update `make()` constructor to accept moves array
  - [ ] Add `getMoveSlot()` helper
  - [ ] Add `onMoveFinished()` helper
  - [ ] Add `tryCastMove()` helper

### Phase 2: Move Updates
- [ ] Update `Ember.res`:
  - [ ] Add `move: Move.t` instance
  - [ ] Implement `addRulesForAI` function
  - [ ] Update `cast` to call `Pokemon.onMoveFinished`
- [ ] Update `Thundershock.res`:
  - [ ] Add `move: Move.t` instance
  - [ ] Implement `addRulesForAI` function
  - [ ] Update `cast` to call `Pokemon.onMoveFinished`
- [ ] Update `QuickAttack.res`:
  - [ ] Add `move: Move.t` instance
  - [ ] Implement `addRulesForAI` function
  - [ ] Update `cast` to call `Pokemon.onMoveFinished`

### Phase 3: Player Integration
- [ ] Update `Player.res`:
  - [ ] Add key binding constants
  - [ ] Add key press tracking for j/k/l/;
  - [ ] Replace spacebar attack with move key handling
  - [ ] Pass moves array to `Pokemon.make()`

### Phase 4: UI Updates
- [ ] Update `Healthbar.res`:
  - [ ] Add pokemon reference to healthbar state
  - [ ] Implement `drawMoves()` function
  - [ ] Display move names, PP, and key bindings
  - [ ] Only show for player team
  - [ ] Skip NoMove slots

### Phase 5: AI Integration
- [ ] Update `EnemyAI.res`:
  - [ ] Update `makeRuleSystem()` to add move rules
  - [ ] Implement `selectBestMove()` function
  - [ ] Integrate move selection into AI decision loop
  - [ ] Test AI move selection behavior

### Phase 6: Testing & Polish
- [ ] Test player move casting with all 4 moves
- [ ] Test PP depletion and move unavailability
- [ ] Test cooldown system per move
- [ ] Test AI move selection
- [ ] Test NoMove slots (empty slots)
- [ ] Test healthbar display

---

## Potential Blockers & Considerations

### 1. **Attack.res Component Conflicts**
**Issue:** Moves like QuickAttack add the `Attack` component to the Pokemon itself, while Ember/Thundershock create separate game objects with the Attack component.

**Impact:** The `Pokemon.tryCastMove()` logic needs to handle both patterns. Some moves modify the Pokemon directly (add shader, add attack component), others spawn projectiles.

**Solution:** Each move's `cast` implementation handles its own setup/teardown. The Pokemon should clean up after itself in `onMoveFinished()`, but individual moves are responsible for adding/removing their own components.

---

### 2. **Mobility vs Attack Status**
**Issue:** Some moves block movement (`mobility = CannotMove`), others don't. There's now both `mobility` and `attackStatus` to manage.

**Current State:**
- `mobility`: Can the Pokemon move? (CanMove/CannotMove)
- `attackStatus`: Can the Pokemon attack? (CanAttack/Attacking) → Will become (CannotAttack/CanAttack(array<int>))

**Consideration:** These are independent systems:
- Thundershock sets `mobility = CannotMove` (Pokemon frozen during attack)
- Ember leaves `mobility = CanMove` (Pokemon can move while projectile flies)
- Both set `attackStatus = Attacking` (now `CannotAttack`) to prevent other moves

**Solution:** Keep both fields independent. Moves control mobility if needed, and `attackStatus` always blocks simultaneous move execution.

---

### 3. **Cooldown Timing**
**Issue:** Each move has its own cooldown, but `attackStatus` is global.

**Example:** 
- Player casts Thundershock (1s cooldown, blocks movement)
- Thundershock finishes at 1s, sets `mobility = CanMove`
- Player should be able to cast QuickAttack (0.4s cooldown) immediately
- But if Thundershock is still on cooldown (PP/time check), it shouldn't be available

**Solution:** The `CanAttack(array<int>)` variant solves this. After Thundershock finishes:
1. Call `Pokemon.onMoveFinished(k)`
2. This recalculates available moves based on each move's `canCast` check
3. Thundershock might still be on cooldown → not in available array
4. QuickAttack is ready → included in available array
5. `attackStatus = CanAttack([1, 2, 3])` (assuming QuickAttack is at index 1)

---

### 4. **Move Reference Equality for NoMove**
**Issue:** Healthbar checks `slot.move.id == 0` to detect NoMove. This requires NoMove to always use ID 0.

**Solution:** Reserve ID 0 for NoMove. Document this clearly. Alternative: add `isNoOp: bool` field to Move.t.

**Recommendation:** Stick with ID check for simplicity. Add a constant:
```rescript
// In Move.res
let noMoveId = 0
```

---

### 5. **AI Rule Fact Naming**
**Issue:** Moves need to assert facts with predictable names so EnemyAI can query them.

**Solution:** Use `moveFactNames` record passed to `addRulesForAI`. This centralizes naming and makes it easy to extend later.

**Example:**
```rescript
type moveFactNames = {
  available: string,
  successRate: string,
}

// Future extension:
type moveFactNames = {
  available: string,
  successRate: string,
  damageEstimate: string,  // New field
  riskLevel: string,       // New field
}
```

---

### 6. **Circular Dependency Resolution (RESOLVED)**
**Issue:** Move modules need access to `Pokemon.t` and `EnemyAIRuleSystemState.t`, but Pokemon needs `Move.t` - creating a circular dependency.

**Solution Implemented:** Use **abstract types** in `Move.res`:
- Define abstract types `pokemon` and `aiState` in `Move.res`
- Use `%identity` external functions to convert between abstract and concrete types
- Conversion happens at boundaries:
  - Pokemon.res converts `Pokemon.t → pokemon` when calling `move.cast()`
  - EnemyAI.res converts `EnemyAIRuleSystemState.t → aiState` when calling `addRulesForAI()`
  - Move implementations convert back: `pokemon → Pokemon.t` and `aiState → EnemyAIRuleSystemState.t`

**Trade-off:** Requires two lines of casting per move implementation, but provides compile-time safety and breaks the circular dependency without dynamic registries.

---

### 7. **Healthbar Pokemon Reference**
**Issue:** Healthbar needs access to Pokemon to display moves, but currently it only stores pokemon metadata (name, level, team).

**Current:** Healthbar receives pokemon in `make()`, subscribes to `onHurt`, but doesn't retain a reference.

**Solution:** Store a pokemon reference in healthbar state:
```rescript
type t = {
  mutable healthPercentage: float,
  mutable tweenControllerRef?: TweenController.t,
  name: string,
  level: int,
  team: Team.t,
  pokemon: Pokemon.t,  // Add this
}
```

Then in `draw()`, access `pokemon` to iterate over moves.

---

### 8. **PP Restoration**
**Issue:** PP depletes during battle. How does it restore?

**Current Design:** PP is mutable and decreases with each cast. There's no restoration logic.

**Consideration:** For now, PP resets when Pokemon is created (constructor sets `currentPP = maxPP`). Future: add PP restoration items, or reset between battles.

**Action:** Document that PP restoration is out of scope for this phase. Reset happens on Pokemon creation only.

---

### 9. **Move Loading (Sprites/Shaders)**
**Issue:** Moves like Ember and Thundershock have `load()` functions for sprites/shaders. Who calls these?

**Current:** Game initialization likely calls each move's `load()` manually.

**With Move System:** Each move module still has its own `load()` function. These must be called at game startup.

**Consideration:** If you dynamically load moves later, you'll need a move registry. For now, hardcoded calls are fine.

**Action:** No blocker. Keep existing pattern.

---

### 10. **Move Context (k: Context.t)**
**Issue:** Some moves need access to `Context.t` (QuickAttack, Ember), others have it via `GameContext.k`.

**Current:** Ember and QuickAttack take `k` as parameter. Thundershock uses global `k` from GameContext.

**With Move System:** `cast` signature is `(Context.t, Pokemon.t) => unit`, so all moves receive `k`.

**Action:** Update Thundershock to accept `k` as parameter instead of using global. This makes moves more testable and consistent.

---

## Future Enhancements (Out of Scope)

These are intentionally deferred:

1. **Move Types** (Fire, Electric, Normal, etc.)
2. **Accuracy** as a stat (currently accuracy is emergent from cast logic)
3. **Status Effects** (burn, paralyze, etc.)
4. **Move Priority** (quick moves go first)
5. **PP Restoration** items/mechanics
6. **Move Learning** system (level up, TMs, etc.)
7. **Move Categories** (Physical, Special, Status)
8. **Critical Hits**
9. **Type Effectiveness** (super effective, not very effective)
10. **Move Metadata Persistence** (saving to SQLite)

---

## Summary

This design provides:
- ✅ Fixed 1-4 move slots per Pokemon
- ✅ Per-move PP tracking
- ✅ Per-move cooldown system
- ✅ Independent move execution (some block movement, some don't)
- ✅ Global attack lock (can't cast multiple moves simultaneously)
- ✅ Player keybindings (j/k/l/;)
- ✅ Healthbar move display (player only)
- ✅ AI move selection via rule system
- ✅ Encapsulated move AI logic (each move knows when it's effective)
- ✅ Extensible architecture for future features

The architecture avoids circular dependencies by extracting shared types, maintains backward compatibility with existing moves, and provides clear extension points for future enhancements.
