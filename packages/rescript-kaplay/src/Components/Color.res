module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getColor: T.t => Types.color = "color"

  @set
  external setColor: (T.t, Types.color) => unit = "color"

  /** Add a color from a color type */
  @send
  external addColor: (Context.t, Types.color) => Types.comp = "color"

  /** Add a color from a hex string or css color name */
  @send
  external addColorFromHex: (Context.t, string) => Types.comp = "color"

  /** Add a color from rgb value */
  @send
  external addColorFromRgb: (Context.t, int, int, int) => Types.comp = "color"
}
