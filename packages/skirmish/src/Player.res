open Kaplay
open GameContext

module KeyEdge = {
  type t = {mutable wasDown: bool}

  let make = () => {wasDown: false}

  /** Returns true only on the frame the key is first pressed */
  let isNewPress = (state: t, isDown: bool): bool => {
    let isNew = isDown && !state.wasDown
    state.wasDown = isDown
    isNew
  }
}

let make = (pokemon: Pokemon.t): unit => {
  let jKey = KeyEdge.make()
  let kKey = KeyEdge.make()
  let lKey = KeyEdge.make()
  let semicolonKey = KeyEdge.make()

  k->Context.onUpdate(() => {
    // Detect new key presses for move keys (home row: j/k/l/;)
    let isNewJPress = jKey->KeyEdge.isNewPress(k->Context.isKeyDown(J))
    let isNewKPress = kKey->KeyEdge.isNewPress(k->Context.isKeyDown(K))
    let isNewLPress = lKey->KeyEdge.isNewPress(k->Context.isKeyDown(L))
    let isNewSemicolonPress = semicolonKey->KeyEdge.isNewPress(k->Context.isKeyDown(Semicolon))

    let isUpPressed = k->Context.isKeyDown(Up) || k->Context.isKeyDown(W)
    let isDownPressed = k->Context.isKeyDown(Down) || k->Context.isKeyDown(S)
    let isLeftPressed = k->Context.isKeyDown(Left) || k->Context.isKeyDown(A)
    let isRightPressed = k->Context.isKeyDown(Right) || k->Context.isKeyDown(D)
    let movementPressed = isUpPressed || isDownPressed || isLeftPressed || isRightPressed

    // Handle move key presses (j/k/l/; for slots 0-3)
    if isNewJPress {
      Pokemon.tryCastMove(k, pokemon, 0)
    } else if isNewKPress {
      Pokemon.tryCastMove(k, pokemon, 1)
    } else if isNewLPress {
      Pokemon.tryCastMove(k, pokemon, 2)
    } else if isNewSemicolonPress {
      Pokemon.tryCastMove(k, pokemon, 3)
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
