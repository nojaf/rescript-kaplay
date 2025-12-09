open Kaplay

@unboxed
type horizontalMovement = | @as(true) Left | @as(false) Right

type ruleSystemState = {
  enemy: Pokemon.t,
  player: Pokemon.t,
  mutable playerAttacks: array<Attack.Unit.t>,
  mutable horizontalMovement: option<horizontalMovement>,
  lastAttackAt: float,
}

module Facts: {
  open RuleSystem

  // Base facts: Attack positions
  let attackInCenterOfEnemy: fact
  let attackOnTheLeftOfEnemy: fact
  let attackOnTheRightOfEnemy: fact

  // Base facts: Space availability
  let hasSpaceOnTheLeft: fact
  let hasSpaceOnTheRight: fact

  // Base facts: Player position relative to enemy
  let isPlayerLeft: fact
  let isPlayerRight: fact

  // Derived facts: Threat levels (computed from attack facts)
  let leftThreat: fact
  let rightThreat: fact

  // Derived facts: Preferred dodge direction
  let preferredDodgeLeft: fact
  let preferredDodgeRight: fact
}

let make: (Context.t, ~pokemonId: int, ~level: int, Pokemon.t) => Pokemon.t
let makeRuleSystem: (
  Context.t,
  ~enemy: Pokemon.t,
  ~player: Pokemon.t,
) => RuleSystem.t<ruleSystemState>
let update: (Context.t, RuleSystem.t<ruleSystemState>, unit) => unit
