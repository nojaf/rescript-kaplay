module Comp = (
  T: {
    type t
  },
) => {
  /** `onCollide(t, tag, callback)`
   Register an event runs once when collide with another game obj with certain tag.
   */
  @send
  external onCollide: (T.t, string, ('t, Collision.t) => unit) => unit = "onCollide"

  @send
  external onCollideWithController: (T.t, string, ('t, Collision.t) => unit) => KEventController.t =
    "onCollide"

  @send
  external onCollideEnd: (T.t, 'tag, 't => unit) => KEventController.t = "onCollideEnd"

  @send
  external hasPoint: (T.t, Vec2.World.t) => bool = "hasPoint"

  /**
Register an event runs when clicked
 */
  @send
  external onClick: (T.t, unit => unit) => unit = "onClick"

  /**
Register an event runs when clicked
 */
  @send
  external onClickWithController: (T.t, unit => unit) => KEventController.t = "onClick"

  /**
Register an event runs once when hovered.
 */
  @send
  external onHover: (T.t, unit => unit) => unit = "onHover"

  /**
Register an event runs once when hovered.
 */
  @send
  external onHoverWithController: (T.t, unit => unit) => KEventController.t = "onHover"

  /**
 Register an event runs once when unhovered.
 */
  @send
  external onHoverEnd: (T.t, unit => unit) => unit = "onHoverEnd"

  /**
   Register an event runs once when unhovered.
 */
  @send
  external onHoverEndWithController: (T.t, unit => unit) => KEventController.t = "onHoverEnd"

  /**
  Get all collisions currently happening.
 */
  @send
  external getCollisions: T.t => array<Collision.t> = "getCollisions"

  type areaCompOptions = {
    /** Only Rect and Polygon are supported */
    shape?: Types.shape,
    offset?: Vec2.Local.t,
    scale?: float,
  }

  @send
  external addArea: (Context.t, ~options: areaCompOptions=?) => Types.comp = "area"
}
