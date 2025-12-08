open Kaplay

@unboxed
type dodgeDirection = | @as(true) Left | @as(false) Right

type ruleSystemState = {
  enemy: Pokemon.t,
  player: Pokemon.t,
  mutable playerAttacks: array<Attack.Unit.t>,
  mutable dodgeDirection: option<dodgeDirection>,
  lastAttackAt: float,
}

let make: (Context.t, ~pokemonId: int, ~level: int, Pokemon.t) => Pokemon.t
let makeRuleSystem: (
  Context.t,
  ~enemy: Pokemon.t,
  ~player: Pokemon.t,
) => RuleSystem.t<ruleSystemState>
let update: (Context.t, RuleSystem.t<ruleSystemState>, unit) => unit
