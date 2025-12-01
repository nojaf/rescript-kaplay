open Kaplay
open GameContext

type t

include GameObjRaw.Comp({type t = t})
include Sprite.Comp({type t = t})
include Pos.Comp({type t = t})
include Move.Comp({type t = t})
include Anchor.Comp({type t = t})
include Z.Comp({type t = t})
include Area.Comp({type t = t})
include Attack.Comp({type t = t})

let spriteName = "flame"

let load = () => {
  k->Context.loadSprite(spriteName, "/sprites/moves/flame.png")
}

let cast = (pokemon: Pokemon.t) => {
  let flame: t =
    pokemon->Pokemon.addChild([
      addSprite(k, spriteName),
      addPos(k, 0., 0.),
      addMove(k, pokemon.direction, 120.),
      addZ(k, -1),
      addArea(k),
      pokemon.direction.y < 0. ? addAnchorBottom(k) : addAnchorTop(k),
      pokemon.team == Pokemon.Player ? Team.playerTagComponent : Team.opponentTagComponent,
    ])

  flame->use(
    addAttack(() => {
      Math.Rect.makeWorld(k, flame->worldPos, flame->getWidth, flame->getHeight)
    }),
  )

  flame->onCollide(Pokemon.tag, (other: Pokemon.t, _collision) => {
    if other.pokemonId != pokemon.pokemonId {
      Console.log2("Ember hit", other.pokemonId)
      other->Pokemon.setHp(other->Pokemon.getHp - 1)
      flame->destroy
    }
  })
}
