# EnemyAI Rule System Refactoring Plan

## Current Problem

The `attackIncoming` fact is too broad. It only tells us "there's an attack" but doesn't encode:
- **Where** the attack is relative to the enemy
- **Which directions** are safe to move
- **Where the player** is relative to the enemy

This forces the action handler to compute these at runtime, leading to complex branching logic (if/else chains) that should be handled by the rule system itself.

### Current Issues

1. **Too much branching in action handler**: Lines 148-167 have nested if/else logic that makes decisions
2. **Runtime computation**: `verifyAttacks()` function computes attack positions every frame
3. **Boundary checking in actions**: Space calculations happen in the action handler
4. **Mixed concerns**: Decision-making logic is split between rules and actions

## Suggested Fact Decomposition

### 1. Attack Direction Facts
Replace the need for `verifyAttacks()` computation by encoding attack positions as facts:

- **`attackFromLeft`** - At least one attack is to the left of the enemy
- **`attackFromRight`** - At least one attack is to the right of the enemy  
- **`attackAligned`** - At least one attack is aligned with the enemy (same X position)
- **`attackOnBothSides`** - Attacks exist on both left and right sides

**Benefits**: The rule system becomes aware of attack positions, eliminating the need for `verifyAttacks()` in the action handler.

### 2. Safety/Movement Facts
Encode safe movement directions and space availability as facts:

- **`safeToMoveLeft`** - No attack blocking left movement
- **`safeToMoveRight`** - No attack blocking right movement
- **`moreSpaceOnLeft`** - More space available on the left side (boundary check)
- **`moreSpaceOnRight`** - More space available on the right side (boundary check)

**Benefits**: Boundary checks and space calculations become facts that rules can reason about, rather than runtime computations in actions.

### 3. Player Position Facts
Extend existing player position facts:

- **`playerOnLeft`** - Player is to the left of the enemy
- **`playerOnRight`** - Player is to the right of the enemy
- **`playerCentered`** - Already exists ✓

**Benefits**: Helps decide movement direction when not dodging attacks.

## Benefits of This Approach

1. **Action handler becomes declarative**: Just checks facts and executes simple actions
2. **Rules encode the logic**: Predicates assert/retract facts based on game state
3. **Easier to test**: Can verify facts are asserted correctly
4. **More composable**: Combine facts to make decisions (e.g., `attackFromLeft && safeToMoveRight => moveRight`)

## Example Rule Structure

### Before (Current Approach)
```rescript
if attackIncoming {
  if attackOnTheLeft { 
    move right 
  } else if attackOnTheRight { 
    move left 
  } else { 
    check space and move 
  }
}
```

### After (Proposed Approach)
Rules would assert facts:
- `attackFromLeft && safeToMoveRight => moveRight`
- `attackFromRight && safeToMoveLeft => moveLeft`
- `attackAligned && moreSpaceOnLeft => moveLeft`
- `attackAligned && moreSpaceOnRight => moveRight`

Action handler becomes:
```rescript
switch (facts) {
| (attackFromLeft, safeToMoveRight) => moveRight()
| (attackFromRight, safeToMoveLeft) => moveLeft()
| (attackAligned, moreSpaceOnLeft) => moveLeft()
| (attackAligned, moreSpaceOnRight) => moveRight()
| ...
}
```

## Implementation Notes

1. **Predicates needed**: Create predicates for each new fact (e.g., `isAttackFromLeft`, `isSafeToMoveLeft`, etc.)
2. **Assert/retract pairs**: Each fact needs both asserting and retracting rules (like existing `playerCentered`)
3. **Salience**: May need to order rules so directional facts are computed before movement decisions
4. **State updates**: `playerAttacks` array should be updated before rule execution (already done)

## Questions to Consider

1. Should we keep `attackIncoming` as a high-level fact, or can we derive it from `attackFromLeft || attackFromRight || attackAligned`?
2. How do we handle multiple attacks? Should facts be binary (exists/doesn't exist) or graded (number of attacks)?
3. Should `moreSpaceOnLeft/Right` be computed relative to enemy position or absolute screen boundaries?
4. Do we need `attackOnBothSides` as a separate fact, or can we derive it from `attackFromLeft && attackFromRight`?

