open Kaplay
open GameContext

type t

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

@module("../shaders/glow.frag?raw")
external glowSource: string = "default"

@module("../shaders/outline2px.frag?raw")
external outline2pxSource: string = "default"

@module("../shaders/darken.frag?raw")
external darkenSource: string = "default"

/* Load both front and back sprites for the given pokemon id */
let load = (id: int): unit => {
  k->Context.loadSprite(frontSpriteName(id), frontSpriteUrl(id), ~options={singular: true})
  k->Context.loadSprite(backSpriteName(id), backSpriteUrl(id), ~options={singular: true})
  k->Context.loadShader("glow", ~frag=glowSource)
  k->Context.loadShader("outline2px", ~frag=outline2pxSource)
  k->Context.loadShader("darken", ~frag=darkenSource)
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

  // For experimentation: apply the red 2px outline shader around the sprite
  let widthPx = gameObj->getWidth
  let heightPx = gameObj->getHeight
  // gameObj->use(addShader(k, "darken"))
  // gameObj->use(addShader(k, "outline2px", ~uniform=() => {
  //   "u_resolution": k->Context.vec2(widthPx, heightPx),
  //   "u_color": k->Color.cyan,
  // }))
  // Apply animated glow using distance field similar to outline2px
  gameObj->use(
    addShader(k, "glow", ~uniform=() =>
      {
        "u_time": k->Context.time,
        "u_resolution": k->Context.vec2(widthPx, heightPx),
        "u_thickness": 0.7,
        "u_color": k->Color.fromHex("#fef9c2"), // Thundershock.lighting2,
        "u_intensity": 0.66,
        "u_pulse_speed": 5.0,
      }
    ),
  )

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
      // Move up
      gameObj->move(k->Context.vec2Up->Vec2.scale(speed))
      gameObj->setSprite(backSpriteName(id))
    } else if downDown && !upDown {
      // Move down
      gameObj->move(k->Context.vec2Down->Vec2.scale(speed))
      gameObj->setSprite(frontSpriteName(id))
    } else if leftDown && !rightDown {
      // Move left
      gameObj->move(k->Context.vec2Left->Vec2.scale(speed))
    } else if rightDown && !leftDown {
      // Move right
      gameObj->move(k->Context.vec2Right->Vec2.scale(speed))
    } else {
      ()
    }
  })

  k->Context.onKeyRelease(key => {
    switch key {
    | Space => Thundershock.make(addChild(gameObj, ...), gameObj->getPos, k->Context.vec2Up)
    | _ => ()
    }
  })

  gameObj
}
