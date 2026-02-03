# Skirmish Package - Agent Guidelines

## Overview

This is a Pokemon battle game built with ReScript and Kaplay. Pokemon can have 1-4 moves, each with PP tracking, cooldowns, and AI integration.

## Build & Test Commands

```bash
# Build the project
bunx rescript

# Run tests
bunx vitest run

# Dev server (usually already running)
bunx vite
```

## Project Structure

```
src/
├── Pokemon.res          # Pokemon entity with move slots, health, position
├── PkmnMove.res         # Move type definition and canCast logic
├── Player.res           # Player input handling (j/k/l/; keys for moves 0-3)
├── Healthbar.res        # UI for displaying moves, PP, cooldowns
├── EnemyAI/             # Rule-based AI system
│   ├── AIFacts.res      # Central registry of fact names
│   ├── MoveFacts.res    # Move availability and selection
│   └── ...
└── Moves/
    ├── ZeroMove.res     # Empty slot placeholder (id = -1)
    ├── Ember.res        # Projectile move example
    ├── Thundershock.res # Complex drawing move example
    ├── QuickAttack.res  # Movement-based attack example
    └── Attack.res       # Attack component for spatial queries
```

## Creating a New Move

### Step 1: Create the Move File

Create a new file in `src/Moves/YourMove.res`. Every move must export a `move: PkmnMove.t` record.

### Step 2: Define the Move Record

The `PkmnMove.t` type requires these fields:

```rescript
let move: PkmnMove.t = {
  id: int,              // Unique ID (avoid -1, reserved for ZeroMove)
  name: string,         // Display name shown in healthbar
  maxPP: int,           // Maximum PP (typically 25-30)
  baseDamage: int,      // Base damage value
  coolDownDuration: float,  // Seconds before move can be used again
  cast: (Context.t, PkmnMove.pkmn) => unit,  // Execute the move
  addRulesForAI: (Context.t, RuleSystem.t<PkmnMove.enemyAIRuleSystemState>, PkmnMove.moveSlot, PkmnMove.moveFactNames) => unit,
}
```

### Step 3: Implement the `cast` Function

The cast function receives:
- `k: Context.t` - Kaplay context for creating game objects, timing, etc.
- `pkmn: PkmnMove.pkmn` - Abstract pokemon type (convert with `Pokemon.fromAbstractPkmn`)

Common patterns:

```rescript
let cast = (k: Context.t, pokemon: Pokemon.t) => {
  // Get pokemon position
  let pokemonWorldPos = pokemon->Pokemon.worldPos
  
  // Get attack direction (up for player, down for opponent)
  let direction = pokemon.direction
  
  // Create projectile or effect...
  
  // Handle collision with other pokemon
  gameObj->onCollide(Pokemon.tag, (other: Pokemon.t, _collision) => {
    if other.pokemonId != pokemon.pokemonId {
      other->Pokemon.setHp(other->Pokemon.getHp - damage)
      gameObj->destroy
    }
  })
}

// In the move record:
cast: (k, pkmn) => cast(k, pkmn->Pokemon.fromAbstractPkmn),
```

### Step 4: Implement AI Rules

For moves that should be used by enemy AI, implement `addRulesForAI`. Use `PkmnMove.defaultAddRulesForAI` if you only need basic availability checking.

**Simple AI (no custom logic):**
```rescript
addRulesForAI: PkmnMove.defaultAddRulesForAI,
```

**Custom AI rules (like Ember - only attack when safe):**
```rescript
let addRulesForAI = (
  _k: Context.t,
  rs: RuleSystem.t<PkmnMove.enemyAIRuleSystemState>,
  _moveSlot: PkmnMove.moveSlot,
  factNames: PkmnMove.moveFactNames,
) => {
  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      // Check conditions (e.g., not under threat, move available)
      let RuleSystem.Grade(available) = rs->RuleSystem.gradeForFact(factNames.available)
      available > 0.0
    },
    rs => {
      rs->RuleSystem.assertFact(AIFacts.shouldAttack)
    },
    ~salience=RuleSystem.Salience(30.0),
  )
}
```

**No AI (player-only move):**
```rescript
addRulesForAI: (_k, _rs, _slot, _facts) => (),
```

### Step 5: Add Asset Loading (If Needed)

If your move uses sprites or shaders, add a `load` function:

```rescript
let spriteName = "mySprite"

let load = (k: Context.t) => {
  k->Context.loadSprite(spriteName, "/sprites/moves/mysprite.png")
}
```

### Step 6: Wire Up the Move

1. **Load assets in `Game.res`:**
   ```rescript
   let scene = () => {
     // ... existing loads ...
     YourMove.load(k)
   }
   ```

2. **Assign to a Pokemon:**
   ```rescript
   let charmander = Pokemon.make(
     k,
     ~pokemonId=4,
     ~level=5,
     ~move1=Ember.move,
     ~move2=YourMove.move,  // Add your move here
     Team.Opponent,
   )
   ```

## Key Concepts

### Attack Component

Moves that create separate game objects (projectiles, effects) should include the Attack component for AI spatial queries:

```rescript
include Attack.Comp({type t = t})

// In the game object creation:
...addAttackWithTag(@this (obj: t) => {
  Kaplay.Math.Rect.makeWorld(k, obj->worldPos, obj->getWidth, obj->getHeight)
}),
```

### Mobility vs Attack Status

These are independent states:
- `mobility: CanMove | CannotMove` - Can the Pokemon move?
- `attackStatus: CannotAttack | CanAttack(array<int>)` - Can the Pokemon attack?

Some moves block movement (Thundershock), others don't (Ember).

### Cooldown Handling

Cooldowns are handled automatically by `Pokemon.tryCastMove`. You only need to set `coolDownDuration` in the move record. After casting:
1. PP decrements
2. `lastUsedAt` is recorded
3. `attackStatus` becomes `CannotAttack`
4. After `coolDownDuration`, `finishAttack` recalculates available moves

### Team Tags

Use team tags for collision filtering:
```rescript
Team.getTagComponent(pokemon.team)  // Adds appropriate tag
Team.player  // "team-player" tag
Team.opponent  // "team-opponent" tag
```

## Existing Move Examples

| Move | Type | Blocks Movement | AI Rules | Notes |
|------|------|-----------------|----------|-------|
| Ember | Projectile | No | Custom (attack when safe) | Simple sprite that moves in direction |
| Thundershock | Drawing | Yes | None | Complex zigzag lightning with custom draw |
| QuickAttack | Movement | Yes | None | Pokemon dashes forward with collision |
| ZeroMove | None | N/A | None | Placeholder for empty slots (id = -1) |

## Testing Moves

Add tests to `tests/PkmnMoveTests.spec.res` for pure logic, or `tests/EnemyAITests.spec.res` for integration tests using `withKaplayContext`.
