/** Module for move-related facts and selection logic */
open Kaplay

// Add rules for all move slots
let addRules = (k: Context.t, rs: RuleSystem.t<Pokemon.ruleSystemState>) => {
  let enemy = rs.state.enemy

  // Add default availability rules for each move slot
  PkmnMove.defaultAddRulesForAI(k, rs, enemy.moveSlot1, PkmnMove.move0Facts)
  PkmnMove.defaultAddRulesForAI(k, rs, enemy.moveSlot2, PkmnMove.move1Facts)
  PkmnMove.defaultAddRulesForAI(k, rs, enemy.moveSlot3, PkmnMove.move2Facts)
  PkmnMove.defaultAddRulesForAI(k, rs, enemy.moveSlot4, PkmnMove.move3Facts)

  // Add move-specific rules (if any)
  enemy.moveSlot1.move.addRulesForAI(k, rs, enemy.moveSlot1, PkmnMove.move0Facts)
  enemy.moveSlot2.move.addRulesForAI(k, rs, enemy.moveSlot2, PkmnMove.move1Facts)
  enemy.moveSlot3.move.addRulesForAI(k, rs, enemy.moveSlot3, PkmnMove.move2Facts)
  enemy.moveSlot4.move.addRulesForAI(k, rs, enemy.moveSlot4, PkmnMove.move3Facts)
}

// Select the first available move, returns None if no moves available
let selectMove = (rs: RuleSystem.t<Pokemon.ruleSystemState>): option<int> => {
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
