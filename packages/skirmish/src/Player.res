open Kaplay
open GameContext

let make = (~pokemonId: int, ~level: int): Pokemon.t => {
  let gameObj: Pokemon.t = Pokemon.make(k, ~pokemonId, ~level, Player)

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

    if isNewSpacePress && gameObj.attackStatus == Pokemon.CanAttack {
      Thundershock.cast(gameObj)
    } else if isUpPressed {
      gameObj.direction = k->Context.vec2Up
      gameObj->Pokemon.setSprite(Pokemon.backSpriteName(pokemonId))
    } else if isDownPressed {
      gameObj.direction = k->Context.vec2Down
      gameObj->Pokemon.setSprite(Pokemon.frontSpriteName(pokemonId))
    } else if isLeftPressed {
      gameObj.direction = k->Context.vec2Left
    } else if isRightPressed {
      gameObj.direction = k->Context.vec2Right
    }

    if gameObj.mobility == Pokemon.CanMove && movementPressed {
      gameObj->Pokemon.move(
        gameObj.direction->Vec2.Unit.asWorld->Vec2.World.scaleWith(Pokemon.movementSpeed),
      )
    }
  })

  gameObj
}
