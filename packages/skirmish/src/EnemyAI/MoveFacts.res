/** Module for move-related facts and selection logic */
open Kaplay

external toAbstractRuleSystem: RuleSystem.t<RuleSystemState.t> => RuleSystem.t<
  PkmnMove.enemyAIRuleSystemState,
> = "%identity"

// Add rules for all move slots
let addRules = (k: Context.t, rs: RuleSystem.t<RuleSystemState.t>) => {
  let enemy = rs.state.enemy
  let abstractRs = rs->toAbstractRuleSystem

  // Add default availability rules for each move slot
  PkmnMove.defaultAddRulesForAI(k, abstractRs, enemy.moveSlot1, PkmnMove.move0Facts)
  PkmnMove.defaultAddRulesForAI(k, abstractRs, enemy.moveSlot2, PkmnMove.move1Facts)
  PkmnMove.defaultAddRulesForAI(k, abstractRs, enemy.moveSlot3, PkmnMove.move2Facts)
  PkmnMove.defaultAddRulesForAI(k, abstractRs, enemy.moveSlot4, PkmnMove.move3Facts)

  // Add move-specific rules (if any)
  enemy.moveSlot1.move.addRulesForAI(k, abstractRs, enemy.moveSlot1, PkmnMove.move0Facts)
  enemy.moveSlot2.move.addRulesForAI(k, abstractRs, enemy.moveSlot2, PkmnMove.move1Facts)
  enemy.moveSlot3.move.addRulesForAI(k, abstractRs, enemy.moveSlot3, PkmnMove.move2Facts)
  enemy.moveSlot4.move.addRulesForAI(k, abstractRs, enemy.moveSlot4, PkmnMove.move3Facts)
}

// Select the first available move, returns None if no moves available
let selectMove = (rs: RuleSystem.t<RuleSystemState.t>): option<int> => {
  let moveFacts = [
    PkmnMove.move0Facts,
    PkmnMove.move1Facts,
    PkmnMove.move2Facts,
    PkmnMove.move3Facts,
  ]

  moveFacts
  ->Array.filterMapWithIndex((facts, index) => {
    let RuleSystem.Grade(grade) = rs->RuleSystem.gradeForFact(facts.available)
    grade > 0.0 ? Some(index) : None
  })
  ->Array.get(0)
}
