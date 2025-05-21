module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  @send
  external addAnchorCenter: (Context.t, @as("center") _) => Types.comp = "anchor"
}
