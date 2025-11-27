open Kaplay
open GameContext

let make = (~pokemonId: int, ~level: int): Pokemon.t => {
  let gameObj: Pokemon.t = Pokemon.make(~pokemonId, ~level, Player)

  k->Context.onKeyRelease(key => {
    let isYAxis = !(gameObj.direction.y == 0.)
    switch key {
    | Space => if isYAxis {
        // If you remove this call, the issue no longer reproduces:
        Thundershock.cast(gameObj)
      }
    | _ => ()
    }
  })

  gameObj
}
