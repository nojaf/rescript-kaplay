open Types

module Rect = {
  @send @scope("Rect")
  external fromPoints: (Context.t, Vec2.World.t, Vec2.World.t) => rect = "fromPoints"

  let make: (Context.t, Vec2.World.t, float, float) => rect = %raw(`
function (k, pos, width, height) {
    return new k.Rect(pos, width, height);
}
`)

  @send
  external contains: (rect, Vec2.World.t) => bool = "contains"

  external asShape: rect => shape = "%identity"
}

module Circle = {
  /** center, radius */
  let make: (Context.t, Vec2.World.t, float) => circle = %raw(`
function (k, center, radius) {
    return new k.Circle(center, radius);
}
`)

  external asShape: circle => shape = "%identity"
}

module Polygon = {
  let make: (Context.t, array<Vec2.World.t>) => polygon = %raw(`
function (k,  points) {
    return new k.Polygon(points);
}
`)

  external asShape: polygon => shape = "%identity"
}
