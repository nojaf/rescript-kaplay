open Kaplay

let move: PkmnMove.t = {
  id: -1,
  name: "Zero move",
  maxPP: 0,
  baseDamage: 0,
  coolDownDuration: 0.,
  cast: (_: Context.t, _: PkmnMove.pkmn) => (),
  addRulesForAI: (
    _: PkmnMove.enemyAIRuleSystemState,
    _: PkmnMove.moveSlot,
    _: PkmnMove.enemyAIRuleSystemState,
    _: PkmnMove.moveFactNames,
  ) => (),
}
