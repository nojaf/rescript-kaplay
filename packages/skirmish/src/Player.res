open Kaplay
open GameContext

let make = (~pokemonId: int, ~level: int): Pokemon.t => {
  let gameObj: Pokemon.t = Pokemon.make(~pokemonId, ~level, Player)

  /* Continuous movement on key press, single direction at a time (no diagonals). */
  k->Context.onUpdate(() => {
    let leftDown = k->Context.isKeyDown(Left) || k->Context.isKeyDown(A)
    let rightDown = k->Context.isKeyDown(Right) || k->Context.isKeyDown(D)
    let upDown = k->Context.isKeyDown(Up) || k->Context.isKeyDown(W)
    let downDown = k->Context.isKeyDown(Down) || k->Context.isKeyDown(S)

    if !(leftDown || rightDown || upDown || downDown) {
      // No key was pressed
      ()
    } else {
      /* Y axis has priority over X; ignore X when any vertical key is active (not both). */
      if upDown && !downDown {
        // Move up
        gameObj.direction = k->Context.vec2Up
        gameObj->Pokemon.setSprite(Pokemon.backSpriteName(pokemonId))
      } else if downDown && !upDown {
        // Move down
        gameObj.direction = k->Context.vec2Down
        gameObj->Pokemon.setSprite(Pokemon.frontSpriteName(pokemonId))
      } else if leftDown && !rightDown {
        // Move left
        gameObj.direction = k->Context.vec2Left
      } else if rightDown && !leftDown {
        // Move right
        gameObj.direction = k->Context.vec2Right
      }

      gameObj->Pokemon.move(gameObj.direction->Vec2.scaleWith(Pokemon.movementSpeed))
    }
  })

  k->Context.onKeyRelease(key => {
    switch key {
    | Space => Thundershock.cast(gameObj)
    | _ => ()
    }
  })

  gameObj
}
