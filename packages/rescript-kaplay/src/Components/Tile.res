module Comp = (
  T: {
    type t
  },
) => {
  type tileOptions = {
    isObstacle?: bool,
    cost?: int,
    offset?: Vec2.World.t,
  }

  @send
  external addTile: (Context.t, ~options: tileOptions=?) => Types.comp = "tile"
}
