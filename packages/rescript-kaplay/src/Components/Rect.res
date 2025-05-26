module Comp = (
  T: {
    type t
  },
) => {
  type rectOptions = {
    radius?: float,
    fill?: bool,
  }

  @send
  external addRect: (Context.t, float, float, ~options: rectOptions=?) => Types.comp = "rect"
}
