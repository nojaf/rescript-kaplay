open Kaplay

module BaseFacts: {
  let addRules: (Context.t, RuleSystem.t<RuleSystemState.t>) => unit
}

module DerivedFacts: {
  let addRules: RuleSystem.t<RuleSystemState.t> => unit
}

module DefensiveFacts: {
  let addRules: RuleSystem.t<RuleSystemState.t> => unit
}

module AttackFacts: {
  let shouldAttack: RuleSystem.fact
}

module MoveFacts: {
  let selectMove: RuleSystem.t<RuleSystemState.t> => option<int>
}

let make: (Context.t, ~enemy: Pokemon.t, ~player: Pokemon.t) => unit
let makeRuleSystem: (
  Context.t,
  ~enemy: Pokemon.t,
  ~player: Pokemon.t,
) => RuleSystem.t<RuleSystemState.t>
let update: (Context.t, RuleSystem.t<RuleSystemState.t>, unit) => unit
