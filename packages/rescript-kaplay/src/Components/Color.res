module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  @get
  external getColor: T.t => Types.color = "color"

  @set
  external setColor: (T.t, Types.color) => unit = "color"

  /** hex value */
  @send
  external addColor: (Context.t, Types.color) => Types.comp = "color"
}
