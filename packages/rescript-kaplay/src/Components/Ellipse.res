module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getRadiusX: T.t => float = "radiusX"

  @get
  external getRadiusY: T.t => float = "radiusY"

  @set
  external setRadiusX: (T.t, float) => unit = "radiusX"

  @set
  external setRadiusY: (T.t, float) => unit = "radiusY"

  @send
  external addEllipse: (Context.t, ~radiusX: float, ~radiusY: float) => Types.comp = "ellipse"
}
