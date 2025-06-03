module Comp = (
  T: {
    type t
  },
) => {
  type rectOptions = {
    radius?: float,
    fill?: bool,
  }

  @get
  external getWidth: T.t => float = "width"

  @set
  external setWidth: (T.t, float) => unit = "width"

  @get
  external getHeight: T.t => float = "height"

  @set
  external setHeight: (T.t, float) => unit = "height"

  @send
  external addRect: (Context.t, float, float, ~options: rectOptions=?) => Types.comp = "rect"
}
