open Kaplay
open GameContext

let make = (pokemon: Pokemon.t): unit => {
  let spaceWasDown = ref(false)

  k->Context.onUpdate(() => {
    let isSpacePressed = k->Context.isKeyDown(Space)
    let isNewSpacePress = isSpacePressed && !spaceWasDown.contents
    spaceWasDown.contents = isSpacePressed

    let isUpPressed = k->Context.isKeyDown(Up) || k->Context.isKeyDown(W)
    let isDownPressed = k->Context.isKeyDown(Down) || k->Context.isKeyDown(S)
    let isLeftPressed = k->Context.isKeyDown(Left) || k->Context.isKeyDown(A)
    let isRightPressed = k->Context.isKeyDown(Right) || k->Context.isKeyDown(D)
    let movementPressed = isUpPressed || isDownPressed || isLeftPressed || isRightPressed

    if isNewSpacePress {
      Pokemon.tryCastMove(k, pokemon, 0)
    } else if isUpPressed {
      pokemon.direction = k->Context.vec2Up
      pokemon->Pokemon.setSprite(Pokemon.backSpriteName(pokemon.pokemonId))
    } else if isDownPressed {
      pokemon.direction = k->Context.vec2Down
      pokemon->Pokemon.setSprite(Pokemon.frontSpriteName(pokemon.pokemonId))
    } else if isLeftPressed {
      pokemon.direction = k->Context.vec2Left
    } else if isRightPressed {
      pokemon.direction = k->Context.vec2Right
    }

    if pokemon.mobility == Pokemon.CanMove && movementPressed {
      pokemon->Pokemon.move(
        pokemon.direction->Vec2.Unit.asWorld->Vec2.World.scaleWith(Pokemon.movementSpeed),
      )
    }
  })
}
