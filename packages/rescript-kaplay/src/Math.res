open Types

/***
 * Shapes are space-agnostic - they're just collections of numbers.
 * The coordinate system depends on where and how you use them:
 * 
 * - Shapes passed to components (area(), polygon()) use LOCAL coordinates
 *   (Kaplay transforms them to world space automatically)
 * - Shapes used for direct world-space operations (contains()) use WORLD coordinates
 */

module Rect = {
  @send @scope("Rect")
  external fromPointsWorld: (Context.t, Vec2.World.t, Vec2.World.t) => rect<Vec2.World.t> =
    "fromPoints"

  /** Create a rectangle for use in components (local coordinates) */
  let makeLocal: (Context.t, Vec2.Local.t, float, float) => rect<Vec2.Local.t> = %raw(`
function (k, pos, width, height) {
    return new k.Rect(pos, width, height);
}
`)

  /** Create a rectangle for direct world-space operations (world coordinates) */
  let makeWorld: (Context.t, Vec2.World.t, float, float) => rect<Vec2.World.t> = %raw(`
function (k, pos, width, height) {
    return new k.Rect(pos, width, height);
}
`)

  @send
  external containsWorld: (rect<Vec2.World.t>, Vec2.World.t) => bool = "contains"

  external asShape: rect<'vec2> => shape<'vec2> = "%identity"

  @send
  external centerWorld: rect<Vec2.World.t> => Vec2.World.t = "center"
}

module Circle = {
  /** Create a circle for use in components (local coordinates) */
  let makeLocal: (Context.t, Vec2.Local.t, float) => circle<Vec2.Local.t> = %raw(`
function (k, center, radius) {
    return new k.Circle(center, radius);
}
`)

  /** Create a circle for direct world-space operations (world coordinates) */
  let makeWorld: (Context.t, Vec2.World.t, float) => circle<Vec2.World.t> = %raw(`
function (k, center, radius) {
    return new k.Circle(center, radius);
}
`)

  external asShape: circle<'vec2> => shape<'vec2> = "%identity"
}

module Polygon = {
  /** Create a polygon for use in components (local coordinates) */
  let makeLocal: (Context.t, array<Vec2.Local.t>) => polygon<Vec2.Local.t> = %raw(`
function (k,  points) {
    return new k.Polygon(points);
}
`)

  /** Create a polygon for direct world-space operations (world coordinates) */
  let makeWorld: (Context.t, array<Vec2.World.t>) => polygon<Vec2.World.t> = %raw(`
function (k,  points) {
    return new k.Polygon(points);
}
`)

  external asShape: polygon<'vec2> => shape<'vec2> = "%identity"
}
