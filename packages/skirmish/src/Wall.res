open Kaplay
open GameContext

type t

include Pos.Comp({type t = t})
include Rect.Comp({type t = t})
include Area.Comp({type t = t})
include Body.Comp({type t = t})
include Color.Comp({type t = t})

let tag = "wall"
let wallColor = k->Color.fromHex("#27272a")

let wallSize = 2.

let worldRect = Kaplay.Math.Rect.makeWorld(
  k,
  k->Context.vec2World(0., Healthbar.OpponentLayout.height),
  k->Context.width,
  k->Context.height - Healthbar.OpponentLayout.height - Healthbar.PlayerLayout.playerHeight,
)

let make = (~pos: Vec2.World.t, ~width: float, ~height: float) => {
  k
  ->Context.add([
    addPosFromWorldVec2(k, pos),
    addRect(k, width, height),
    addColor(k, wallColor),
    addArea(k),
    addBody(k, ~options={isStatic: true}),
    Context.tag(tag),
  ])
  ->ignore
}

let makeAll = () => {
  // Left wall
  make(~pos=worldRect.pos, ~width=wallSize, ~height=worldRect.height)
  // Right wall
  make(
    ~pos=k->Context.vec2World(worldRect.pos.x + worldRect.width - wallSize, worldRect.pos.y),
    ~width=wallSize,
    ~height=worldRect.height,
  )

  // Top wall
  make(
    ~pos=k->Context.vec2World(0., Healthbar.OpponentLayout.height),
    ~width=k->Context.width,
    ~height=wallSize,
  )
  // Bottom wall
  make(
    ~pos=k->Context.vec2World(0., worldRect.pos.y + worldRect.height),
    ~width=worldRect.width,
    ~height=wallSize,
  )
}
