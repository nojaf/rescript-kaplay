module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getWidth: T.t => float = "width"

  @set
  external setWidth: (T.t, float) => unit = "width"

  @get
  external getHeight: T.t => float = "height"

  @set
  external setHeight: (T.t, float) => unit = "height"

  /** Attach and render a UV quad to a Game Object. */
  @send
  external addUVQuad: (Context.t, ~w: float, ~h: float) => Types.comp = "uvquad"
}
