module Comp = (
  T: {
    type t
  },
) => {
  @send
  external jump: (T.t, float) => unit = "jump"

  @send
  external isGrounded: T.t => bool = "isGrounded"

  @send
  external onGround: (T.t, unit => unit) => unit = "onGround"

  @send
  external onGroundWithController: (T.t, unit => unit) => KEventController.t = "onGround"

  @send
  external applyImpulse: (T.t, Vec2.World.t) => unit = "applyImpulse"

  @get
  external getVel: T.t => Vec2.World.t = "vel"

  @set
  external setVel: (T.t, Vec2.World.t) => unit = "vel"

  /** Gravity multiplier. */
  @get
  external getGravityScale: T.t => float = "gravityScale"

  @set
  external setGravityScale: (T.t, float) => unit = "gravityScale"

  /** If object is static, it won't move, all non static objects won't move past it,
  and all calls to addForce(), applyImpulse(), or jump() on this body will do absolutely nothing. **/
  @get
  external getIsStatic: T.t => bool = "isStatic"

  @set
  external setIsStatic: (T.t, bool) => unit = "isStatic"

  type bodyOptions = {isStatic?: bool}

  /**
Physical body that responds to gravity.
Requires "area" and "pos" comp.
This also makes the object "solid".
 */
  @send
  external addBody: (Context.t, ~options: bodyOptions=?) => Types.comp = "body"
}
