module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  type offscreenOptions = {
    hide?: bool,
    pause?: bool,
    destroy?: bool,
    distance?: int,
  }

  @send
  external addOffScreen: (Context.t, ~options: offscreenOptions=?) => Types.comp = "offscreen"
}
