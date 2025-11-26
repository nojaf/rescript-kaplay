open Kaplay
open GameContext

let addEnemyAI = (player: Pokemon.t) => {
  let update =
    @this
    (self: Pokemon.t) => {
      self->Pokemon.move(self.direction->Vec2.scaleWith(20.))
    }
  CustomComponent.make({
    id: "enemy-ai",
    update,
  })
}

let make = (~pokemonId: int, ~level: int, player: Pokemon.t): Pokemon.t => {
  let gameObj: Pokemon.t = Pokemon.make(~pokemonId, ~level, Opponent)

  gameObj->Pokemon.use(addEnemyAI(player))

  gameObj
}
