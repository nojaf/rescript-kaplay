module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  /**
 Move towards a direction infinitely, and destroys when it leaves game view.
 */
  @send
  external addMove: (Context.t, Vec2.t, float) => Types.comp = "move"
}
