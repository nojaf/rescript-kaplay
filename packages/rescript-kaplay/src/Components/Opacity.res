module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getOpacity: T.t => float = "opacity"

  @set
  external setOpacity: (T.t, float) => unit = "opacity"

  /** Value between 0 and 1 */
  @send
  external addOpacity: (Context.t, float) => Types.comp = "opacity"
}
