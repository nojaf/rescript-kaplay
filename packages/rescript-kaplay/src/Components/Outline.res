module Comp = (
  T: {
    type t
  },
) => {
  /**
   `addOutline(context, ~width=?, ~color=?, ~opacity=?)` adds an outline to the component.
   */
  @send
  external addOutline: (
    Context.t,
    ~width: float=?,
    ~color: Types.color=?,
    ~opacity: float=?,
  ) => Types.comp = "outline"
}
