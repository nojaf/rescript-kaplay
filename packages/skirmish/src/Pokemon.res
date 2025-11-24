open Kaplay
open GameContext

type t = {mutable direction: Vec2.t}

include GameObjRaw.Comp({type t = t})
include Pos.Comp({type t = t})
include Sprite.Comp({type t = t})
include Area.Comp({type t = t})
include Health.Comp({type t = t})
include Anchor.Comp({type t = t})
include Shader.Comp({type t = t})

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

external asRuntime: t => RuntimePokemon.t<'t> = "%identity"

/* Create a Pokemon game object at center, with hp 20, center anchor, default area.
 Uses the back-facing sprite by default. */
let make = (id: int): t => {
  let gameObj: t = k->Context.add([
    // initialState
    Obj.magic({direction: k->Context.vec2Up}),
    k->addPos(k->Context.center->Vec2.x, k->Context.height * 0.8),
    k->addSprite(backSpriteName(id)),
    k->addArea,
    k->addHealth(20),
    k->addAnchorCenter,
    Context.tag(tag),
  ])

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
    | Space => {
        Console.log("Triggering Thundershock")
        Thundershock.cast(gameObj->asRuntime)
      }
    | _ => ()
    }
  })

  gameObj
}
