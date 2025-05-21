module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  type tileOptions = {
    isObstacle?: bool,
    cost?: int,
    offset?: Vec2.t,
  }

  @send
  external addTile: (Context.t, ~options: tileOptions=?) => Types.comp = "tile"
}
