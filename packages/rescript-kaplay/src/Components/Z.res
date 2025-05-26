module Comp = (
  T: {
    type t
  },
) => {
  @send
  external addZ: (Context.t, int) => Types.comp = "z"
}
