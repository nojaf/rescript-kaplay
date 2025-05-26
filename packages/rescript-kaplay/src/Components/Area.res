module Comp = (
  T: {
    type t
  },
) => {
  @send
  external onCollide: (T.t, string, ('t, Collision.t) => unit) => KEventController.t = "onCollide"

  @send
  external onCollideEnd: (T.t, 'tag, 't => unit) => KEventController.t = "onCollideEnd"

  @send
  external hasPoint: (T.t, Vec2.t) => bool = "hasPoint"

  /**
Register an event runs when clicked
 */
  @send
  external onClick: (T.t, unit => unit) => KEventController.t = "onClick"

  /**
Register an event runs once when hovered.
 */
  @send
  external onHover: (T.t, string, unit => unit) => KEventController.t = "onHover"

  type areaCompOptions = {
    /** Only Rect and Polygon are supported */
    shape?: Math.Shape.t,
    offset?: Vec2.t,
    scale?: float,
  }

  @send
  external addArea: (Context.t, ~options: areaCompOptions=?) => Types.comp = "area"
}
