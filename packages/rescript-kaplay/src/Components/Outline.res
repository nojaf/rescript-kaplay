module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getOutline: T.t => Types.outline = "outline"

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
