module Comp = (
  T: {
    type t
  },
) => {
  /**
  `move(gameObj, velocity)` moves the object by `velocity` every frame with delta time applied internally.

  - `velocity`: a vector in units per second (do NOT multiply by `dt` yourself)
  - Frame-rate independent: Kaplay scales by `dt` under the hood

  Example:

  ```ReScript
  open Kaplay

  // Example context instance
  external k: Context.t = "k"

  let speed = k->Context.vec2(200., 200.)
  k->Context.onUpdate(() => {
    // Move left at 200 units/second
    myObj->MyModule.move(k->Context.vec2Left->Vec2.scale(speed))
  })
  ```
  */
  @send
  external move: (T.t, Vec2.t) => unit = "move"

  @send
  external worldPos: T.t => Vec2.t = "worldPos"

  @send
  external setWorldPos: (T.t, Vec2.t) => unit = "worldPos"

  @send
  external screenPos: T.t => Vec2.t = "screenPos"

  @send
  external setScreenPos: (T.t, Vec2.t) => unit = "screenPos"

  @get
  external getPos: T.t => Vec2.t = "pos"

  @get @scope("pos")
  external getPosX: T.t => float = "x"

  @get @scope("pos")
  external getPosY: T.t => float = "y"

  @set
  external setPos: (T.t, Vec2.t) => unit = "pos"

  @send
  external addPos: (Context.t, float, float) => Types.comp = "pos"

  @send
  external addPosFromVec2: (Context.t, Vec2.t) => Types.comp = "pos"
}
