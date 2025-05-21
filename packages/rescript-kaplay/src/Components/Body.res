module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  @send
  external jump: (T.t, float) => unit = "jump"

  @send
  external isGrounded: T.t => bool = "isGrounded"

  @send
  external onGround: (T.t, unit => unit) => KEventController.t = "onGround"

  type bodyOptions = {isStatic?: bool}

  /**
Physical body that responds to gravity.
Requires "area" and "pos" comp.
This also makes the object "solid".
 */
  @send
  external addBody: (Context.t, ~options: bodyOptions=?) => Types.comp = "body"
}
