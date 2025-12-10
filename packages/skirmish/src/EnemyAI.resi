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

module BaseFacts: {
  open RuleSystem

  // Attack positions
  let attackInCenterOfEnemy: fact
  let attackOnTheLeftOfEnemy: fact
  let attackOnTheRightOfEnemy: fact

  // Space availability
  let hasSpaceOnTheLeft: fact
  let hasSpaceOnTheRight: fact

  // Player position relative to enemy
  let isPlayerLeft: fact
  let isPlayerRight: fact
}

module DerivedFacts: {
  open RuleSystem

  // Threat levels (computed from attack facts)
  let leftThreat: fact
  let rightThreat: fact
}

module DecisionsFacts: {
  open RuleSystem

  // Preferred dodge direction
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
