module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getText: T.t => string = "text"

  @set
  external setText: (T.t, string) => unit = "text"

  @get
  external width: T.t => float = "width"

  @get
  external height: T.t => float = "height"

  type textAlign =
    | @as("left") Left
    | @as("center") Center
    | @as("right") Right

  type textOptions = {
    size?: float,
    font?: string,
    width?: float,
    align?: textAlign,
    lineSpacing?: float,
    letterSpacing?: float,
  }

  @send
  external addText: (Context.t, string, ~options: textOptions=?) => Types.comp = "text"
}
