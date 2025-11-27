open Kaplay
open GameContext

type team = Player | Opponent

type t = {mutable direction: Vec2.t, level: int, pokemonId: int, team: team}

let make = (~pokemonId: int, ~level: int, team: team): t => {
  {direction: k->Context.vec2Up, level, pokemonId, team}
}
