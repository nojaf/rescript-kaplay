open Kaplay

module BaseFacts = BaseFacts
module DerivedFacts = DerivedFacts
module DefensiveFacts = DefensiveFacts
module MoveFacts = MoveFacts

module AttackFacts = {
  let shouldAttack = AIFacts.shouldAttack
}

/** Creates a rule system for enemy AI behavior.
  *
  * **Important**: The rule system is reset on every update (see `update` function).
  * This means all facts are cleared before each execution cycle. As a result, you
  * typically should NOT use `assertFact`/`retractFact` pairs for state management.
  * Instead, use `addRuleAssertingFact` or `addRuleExecutingAction` with `assertFact`
  * to compute facts fresh each frame based on current game state.
  */
let makeRuleSystem = (k: Context.t, ~enemy: Pokemon.t, ~player: Pokemon.t): RuleSystem.t<
  Pokemon.ruleSystemState,
> => {
  let rs = RuleSystem.make(k)
  rs.state = {
    Pokemon.enemy,
    player,
    playerAttacks: [],
    horizontalMovement: None,
    lastAttackAt: 0.,
  }

  BaseFacts.addRules(k, rs)
  DerivedFacts.addRules(rs)
  DefensiveFacts.addRules(rs)
  MoveFacts.addRules(k, rs)

  rs
}

let getPlayerAttacks = (k: Context.t): array<Attack.Unit.t> => {
  k
  ->Context.query({
    include_: [Attack.tag, Team.player],
    hierarchy: Descendants,
  })
  ->Array.filterMap(Attack.Unit.fromGameObj)
}

let update = (k: Context.t, rs: RuleSystem.t<Pokemon.ruleSystemState>, ()) => {
  rs->RuleSystem.reset
  rs.state.playerAttacks = getPlayerAttacks(k)
  rs->RuleSystem.execute

  // Move in the horizontal movement direction if set
  switch rs.state.horizontalMovement {
  | None => ()
  | Some(MoveLeft) => Pkmn.moveLeft(k, rs.state.enemy)
  | Some(MoveRight) => Pkmn.moveRight(k, rs.state.enemy)
  }

  // Check if should attack and select a move to execute
  switch rs->RuleSystem.gradeForFact(AttackFacts.shouldAttack) {
  | RuleSystem.Grade(g) if g > 0.0 =>
    switch MoveFacts.selectMove(rs) {
    | None => ()
    | Some(moveIndex) => Pkmn.tryCastMove(rs.state.enemy, moveIndex)
    }
  | _ => ()
  }
}

let make = (k: Context.t, ~enemy: Pokemon.t, ~player: Pokemon.t): unit => {
  Pkmn.assignOpponent(enemy)

  let rs = makeRuleSystem(k, ~enemy, ~player)

  enemy->Pokemon.onUpdate(update(k, rs, ...))

  if k.debug.inspect {
    DebugRuleSystem.make(k, rs)
  }
}
