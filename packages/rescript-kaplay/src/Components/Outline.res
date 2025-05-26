module Comp = (
  T: {
    type t
  },
) => {
  @send
  external addOutline: (
    Context.t,
    ~width: int=?,
    ~color: Types.color=?,
    ~opacity: float=?,
  ) => Types.comp = "outline"
}
