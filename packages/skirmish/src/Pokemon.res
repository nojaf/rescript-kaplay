open Kaplay
open GameContext

type team = Player | Opponent

type t = {mutable direction: Vec2.t, level: int, pokemonId: int, team: team}

include GameObjRaw.Comp({type t = t})
include Pos.Comp({type t = t})
include Sprite.Comp({type t = t})
include Area.Comp({type t = t})
include Health.Comp({type t = t})
include Anchor.Comp({type t = t})
include Shader.Comp({type t = t})
include Opacity.Comp({type t = t})
include Animate.Comp({type t = t})

let tag = "pokemon"

/* Helpers to consistently compose sprite names and URLs from an id */
let frontSpriteName = (id: int) => "pokemon-" ++ Int.toString(id) ++ "-front"
let backSpriteName = (id: int) => "pokemon-" ++ Int.toString(id) ++ "-back"

let frontSpriteUrl = (id: int) => `/sprites/${Int.toString(id)}-front.png`
let backSpriteUrl = (id: int) => `/sprites/${Int.toString(id)}-back.png`

/* Load both front and back sprites for the given pokemon id */
let load = (id: int): unit => {
  k->Context.loadSprite(frontSpriteName(id), frontSpriteUrl(id), ~options={singular: true})
  k->Context.loadSprite(backSpriteName(id), backSpriteUrl(id), ~options={singular: true})
}

let movementSpeed = 200.

external internalState: t => Types.comp = "%identity"

let getHealthPercentage = (pokemon: t): float => {
  let currentHp = pokemon->getHp->Int.toFloat
  let maxHp = pokemon->getMaxHp->Int.toFloat
  currentHp / maxHp * 100.
}

/* Create a Pokemon game object at center, with hp 20, center anchor, default area.
 Uses the back-facing sprite by default. */
let make = (id: int, level: int, team: team): t => {
  let gameObj: t = k->Context.add(
    [
      // initialState
      ...team == Player
        ? [
            internalState({direction: k->Context.vec2Up, level, pokemonId: id, team}),
            k->addPos(k->Context.center->Vec2.x, k->Context.height * 0.8),
            k->addSprite(backSpriteName(id)),
          ]
        : [
            internalState({direction: k->Context.vec2Down, level, pokemonId: id, team}),
            k->addPos(k->Context.center->Vec2.x, k->Context.height * 0.2),
            k->addSprite(frontSpriteName(id)),
          ],
      k->addArea,
      k->addHealth(20, ~maxHP=20),
      k->addAnchorCenter,
      k->addOpacity(1.),
      k->addAnimate,
      Context.tag(tag),
    ],
  )

  if team == Player {
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
          gameObj->setSprite(backSpriteName(id))
        } else if downDown && !upDown {
          // Move down
          gameObj.direction = k->Context.vec2Down
          gameObj->setSprite(frontSpriteName(id))
        } else if leftDown && !rightDown {
          // Move left
          gameObj.direction = k->Context.vec2Left
        } else if rightDown && !leftDown {
          // Move right
          gameObj.direction = k->Context.vec2Right
        }

        gameObj->move(gameObj.direction->Vec2.scaleWith(movementSpeed))
      }
    })

    k->Context.onKeyRelease(key => {
      switch key {
      | Space => gameObj->trigger((Moves.Thundershock :> string), gameObj)
      | _ => ()
      }
    })
  }

  gameObj->onHurt(deltaHp => {
    Console.log2("I hurt myself today", deltaHp)

    // Stop any existing opacity animation and reset the internal clock
    gameObj->unanimate("opacity")
    gameObj->getAnimation->(animation => animation.seek(0.))

    // Animate opacity: 1.0 → 0.5 → 0.75 → 1.0
    gameObj->animate(
      "opacity",
      [1., 0.5, 1., 0.75, 1.],
      {
        duration: 0.4,
        loops: 1,
      },
    )
  })

  gameObj
}
