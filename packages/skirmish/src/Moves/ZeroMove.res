open Kaplay

// ZeroMove never asserts availability - it's an empty slot
let move: Pokemon.move = {
  id: -1,
  name: "Zero move",
  maxPP: 0,
  baseDamage: 0,
  coolDownDuration: 0.,
  cast: (_: Context.t, _: Pokemon.t) => (),
  addRulesForAI: (_k, _rs, _slot, _facts) => (),
}
