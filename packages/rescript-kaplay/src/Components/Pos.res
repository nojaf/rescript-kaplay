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
  external move: (T.t, Vec2.World.t) => unit = "move"

  @send
  external worldPos: T.t => Vec2.World.t = "worldPos"

  @send
  external setWorldPos: (T.t, Vec2.World.t) => unit = "worldPos"

  @send
  external fromWorld: (T.t, Vec2.World.t) => Vec2.Local.t = "fromWorld"

  @send
  external screenPos: T.t => Vec2.Screen.t = "screenPos"

  @send
  external setScreenPos: (T.t, Vec2.Screen.t) => unit = "screenPos"

  @get
  external getPos: T.t => Vec2.Local.t = "pos"

  @get @scope("pos")
  external getPosX: T.t => float = "x"

  @get @scope("pos")
  external getPosY: T.t => float = "y"

  @set
  external setPos: (T.t, Vec2.Local.t) => unit = "pos"

  @send
  external addPos: (Context.t, float, float) => Types.comp = "pos"

  @send
  external addPosFromVec2: (Context.t, Vec2.Local.t) => Types.comp = "pos"

  /**
   * Add position from world coordinates.
   * You should only use this if you are adding a position to a root-level object!
   */
  @send
  external addPosFromWorldVec2: (Context.t, Vec2.World.t) => Types.comp = "pos"
}

module Unit = {
  type t
  include GameObjRaw.Comp({type t = t})
  include Comp({type t = t})

  let fromGameObj = (obj: GameObjRaw.Unit.t): option<t> => {
    if obj->GameObjRaw.Unit.has("pos") {
      Some(Obj.magic(obj))
    } else {
      None
    }
  }
}
