module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getFixed: T.t => bool = "fixed"

  @set
  external setFixed: (T.t, bool) => unit = "fixed"

  /** If the obj is unaffected by camera */
  @send
  external addFixed: Context.t => Types.comp = "fixed"
}
