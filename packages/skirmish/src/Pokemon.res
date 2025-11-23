open Kaplay
open GameContext

type t

include Pos.Comp({type t = t})
include Sprite.Comp({type t = t})
include Area.Comp({type t = t})
include Health.Comp({type t = t})
include Anchor.Comp({type t = t})

let tag = "pokemon"

/* Helpers to consistently compose sprite names and URLs from an id */
let frontSpriteName = (id: int) => "pokemon-" ++ Int.toString(id) ++ "-front"
let backSpriteName = (id: int) => "pokemon-" ++ Int.toString(id) ++ "-back"

let frontSpriteUrl = (id: int) => `/sprites/${Int.toString(id)}-front.png`
let backSpriteUrl = (id: int) => `/sprites/${Int.toString(id)}-back.png`

/* Load both front and back sprites for the given pokemon id */
let load = (id: int): unit => {
  k->Context.loadSprite(frontSpriteName(id), frontSpriteUrl(id))
  k->Context.loadSprite(backSpriteName(id), backSpriteUrl(id))
}

let movementSpeed = 200.

/* Create a Pokemon game object at center, with hp 20, center anchor, default area.
   Uses the back-facing sprite by default. */
let make = (id: int): t => {
  let gameObj: t =
    k->Context.add([
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

    /* Kaplay's move applies dt internally; pass velocity in units/second, NOT scaled by dt. */
    let speed = k->Context.vec2(movementSpeed, movementSpeed)

    /* Y axis has priority over X; ignore X when any vertical key is active (not both). */
    if upDown && !downDown {
      gameObj->move(k->Context.vec2Up->Vec2.scale(speed))
    } else if downDown && !upDown {
      gameObj->move(k->Context.vec2Down->Vec2.scale(speed))
    } else if leftDown && !rightDown {
      gameObj->move(k->Context.vec2Left->Vec2.scale(speed))
    } else if rightDown && !leftDown {
      gameObj->move(k->Context.vec2Right->Vec2.scale(speed))
    } else {
      ()
    }
  })

  gameObj
}


