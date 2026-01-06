# Skirmish Game

Real-time Pokemon battle game (shake up turn-based formula).

## Rules

- 0 HP = game over
- Pokemon has 1-4 moves (MVP: min 2, may use generic moves like Tackle)
- Each move:
  - Type (water 2x vs fire) - TBD not implemented
  - PP limit - TBD not implemented
  - Cooldown (wait before reuse) - TBD individual cooldowns exist, global behavior undecided
  - Mechanic (close combat, projectile, buff) - TBD categories: physical/range/buffs

## Goals

- Learn game code structure (pragmatic + extensible balance)
- Create dynamic Rule System for enemy AI (different stats = different experience)
- Focus on core mechanics, scope MVP (types/moves/pokemon counts TBD)
- Incorporate testing (Rule System regression tests with Vitest)

## Enemy AI Implementation

Location: `packages/skirmish/src/EnemyAI.res`
Pattern: Fact decomposition with RuleSystem

### Architecture

**Reset on every update**: All facts cleared before each exec cycle. Facts computed fresh from game state each frame.

**DO NOT use `assertFact`/`retractFact` pairs for state mgmt**. Instead use `addRuleAssertingFact` or `addRuleExecutingAction` with `assertFact` to compute facts from state.

### Salience Tiers

1. **Base Facts (0.0)**: Computed from game state
   - Attack positions: `attackInCenterOfEnemy`, `attackOnTheLeftOfEnemy`, `attackOnTheRightOfEnemy`
   - Space: `hasSpaceOnTheLeft`, `hasSpaceOnTheRight`
   - Player position: `isPlayerLeft`, `isPlayerRight`

2. **Derived Facts (10.0)**: Computed from other facts
   - Threats: `leftThreat`, `rightThreat` (combines attack positions)
   - Preferred dodge: `preferredDodgeLeft`, `preferredDodgeRight` (from threats + space)

3. **Decisions (20.0)**: Action rules setting movement direction
   - Dodging when under center attack
   - Positioning when no attacks

### Fact Decomposition Pattern

- Positional facts: where things are (`attackOnTheLeftOfEnemy`, `isPlayerRight`)
- Space facts: available space (graded 0.0-1.0 continuous)
- Threat facts: combine multiple attack facts into threat levels
- Direction facts: preferred movement direction from threats + space

Makes rules declarative ("when X fact true, do Y") not imperative.

### Implementation Details

1. **Attack detection**: `overlapX` detects if attacks overlap enemy horizontal bounds. Grades from squared distance to personal space.

2. **Oscillation prevention**:
   - Equal threats: keep current direction
   - Positioning: 1px threshold to prevent jitter when aligned

3. **State mgmt**: Movement direction in `ruleSystemState.horizontalMovement` (persists between frames, unlike facts which reset)

4. **Priority**: Dodging (center attack exists) > positioning (no attacks). Both salience 20.0, dodging checked first.

## Testing

Location: `packages/skirmish/tests/EnemyAITests.spec.res`
Run: `bun run test`

- Attack detection tests (center/left/right)
- Positioning tests (move toward player when no attacks)
- Movement verification via spies on enemy `move` method
- Fact assertion verification

Helper: `withKaplayContext` creates test env with 2D playing field:
- `P` = player
- `E` = enemy
- `A` = attack
- `.` = empty

## TBD / Future

- PP system (depletion, replenishment)
- Type effectiveness (0.5x, 1x, 2x damage)
- Level/stats scaling (HP, damage, move availability, speed)
- MVP scope: pokemon types count, move types count, pokemon count, moves per pokemon (2-4)
