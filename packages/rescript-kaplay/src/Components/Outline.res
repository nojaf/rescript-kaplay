module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  @send
  external addOutline: (
    Context.t,
    ~width: int=?,
    ~color: Types.color=?,
    ~opacity: float=?,
  ) => Types.comp = "outline"
}
