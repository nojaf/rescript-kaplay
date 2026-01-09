open Kaplay

type t

include GameObjRaw.Comp({type t = t})
include Sprite.Comp({type t = t})
include Pos.Comp({type t = t})
include Kaplay.Move.Comp({type t = t})
include Anchor.Comp({type t = t})
include Z.Comp({type t = t})
include Area.Comp({type t = t})
include Attack.Comp({type t = t})

let spriteName = "flame"

let load = (k: Context.t) => {
  k->Context.loadSprite(spriteName, "/sprites/moves/flame.png")
}

let coolDown = 1.

let cast = (k: Context.t, pokemon: Pokemon.t) => {
  // Use the pokemon's world position for the flame's position
  // Because flame is using the move component, it will move based on a direction vector relative to the parent.
  // That is why the pokemon cannot be the parent of the flame.
  let pokemonWorldPos = pokemon->Pokemon.worldPos

  let flame: t = k->Context.add(
    [
      addSprite(k, spriteName),
      addPosFromWorldVec2(k, pokemonWorldPos),
      addMove(k, pokemon.direction, 120.),
      addZ(k, -1),
      addArea(k),
      pokemon.direction.y < 0. ? addAnchorBottom(k) : addAnchorTop(k),
      Team.getTagComponent(pokemon.team),
      ...addAttackWithTag(@this (flame: t) => {
        Kaplay.Math.Rect.makeWorld(k, flame->worldPos, flame->getWidth, flame->getHeight)
      }),
    ],
  )

  pokemon.attackStatus = Attacking

  flame->onCollide(Pokemon.tag, (other: Pokemon.t, _collision) => {
    if other.pokemonId != pokemon.pokemonId {
      Console.log2("Ember hit", other.pokemonId)
      other->Pokemon.setHp(other->Pokemon.getHp - 5)
      flame->destroy
    }
  })

  flame->onCollide(Wall.tag, (_: Wall.t, _collision) => {
    flame->destroy
  })

  k->Context.wait(coolDown, () => {
    pokemon.attackStatus = CanAttack
  })
}
