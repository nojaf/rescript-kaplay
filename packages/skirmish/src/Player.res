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
  Pkmn.assignPlayer(pokemon)

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
      Pkmn.tryCastMove(pokemon, 0)
    } else if isNewKPress {
      Pkmn.tryCastMove(pokemon, 1)
    } else if isNewLPress {
      Pkmn.tryCastMove(pokemon, 2)
    } else if isNewSemicolonPress {
      Pkmn.tryCastMove(pokemon, 3)
    } else if isUpPressed {
      if pokemon.facing != FacingUp {
        Pkmn.dispatch(pokemon, FacingChanged(FacingUp))
      }
    } else if isDownPressed {
      if pokemon.facing != FacingDown {
        Pkmn.dispatch(pokemon, FacingChanged(FacingDown))
      }
    } else if isLeftPressed {
      pokemon.direction = k->Context.vec2Left
    } else if isRightPressed {
      pokemon.direction = k->Context.vec2Right
    }

    if pokemon.mobility == Pokemon.CanMove && movementPressed {
      pokemon->Pokemon.move(
        pokemon.direction->Vec2.Unit.asWorld->Vec2.World.scaleWith(Pkmn.movementSpeed),
      )
    }
  })
}
