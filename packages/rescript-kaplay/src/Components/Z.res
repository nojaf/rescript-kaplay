module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  @send
  external addZ: (Context.t, int) => Types.comp = "z"
}
