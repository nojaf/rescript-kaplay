module Comp = (
  T: {
    type t
  },
) => {
  /**
 Move towards a direction infinitely, and destroys when it leaves game view.
 */
  @send
  external addMove: (Context.t, Vec2.t, float) => Types.comp = "move"
}
