module Comp = (
  T: {
    type t
  },
) => {
  @send
  external move: (T.t, Vec2.t) => unit = "move"

  @send
  external worldPos: T.t => Vec2.t = "worldPos"

  @send
  external setWorldPos: (T.t, Vec2.t) => unit = "worldPos"

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
