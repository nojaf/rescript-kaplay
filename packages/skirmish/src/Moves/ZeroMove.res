open Kaplay

// ZeroMove never asserts availability - it's an empty slot
let move: PkmnMove.t = {
  id: -1,
  name: "Zero move",
  maxPP: 0,
  baseDamage: 0,
  coolDownDuration: 0.,
  cast: (_: Context.t, _: PkmnMove.pkmn) => (),
  addRulesForAI: (_k, _rs, _slot, _facts) => (),
}
