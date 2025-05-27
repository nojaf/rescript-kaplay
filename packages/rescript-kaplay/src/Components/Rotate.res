module Comp = (
  T: {
    type t
  },
) => {
  /** `getAngle` in degrees */
  @get
  external getAngle: T.t => float = "angle"

  /** `setAngle` in degrees */
  @set
  external setAngle: (T.t, float) => unit = "angle"

  /** `rotateBy(t, degrees`) */
  @send
  external rotateBy: (T.t, float) => unit = "rotateBy"

  /** `rotateTo(t, degrees)` like directly calling `setAngle` */
  @send
  external rotateTo: (T.t, float) => unit = "rotateTo"

  /** `addRotateBy(context, degrees)` */
  @send
  external addRotateBy: (Context.t, float) => Types.comp = "rotate"

  /**
`addRotate(context, degrees)` rotates a Game Object (in degrees).
 */
  @send
  external addRotate: (Context.t, float) => Types.comp = "rotate"
}
