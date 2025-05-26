module Comp = (
  T: {
    type t
  },
) => {
  @send
  external addAnchorCenter: (Context.t, @as("center") _) => Types.comp = "anchor"
}
