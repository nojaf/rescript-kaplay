module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  type circleOptions = {fill?: bool}

  @send
  external addCircle: (Context.t, float, ~options: circleOptions=?) => Types.comp = "circle"
}
