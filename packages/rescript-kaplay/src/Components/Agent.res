module Comp = (
  T: {
    type t
  },
) => {
  include GameObjRaw.Comp({
    type t = T.t
  })

  /** Part of the agent comp  */
  @send
  external setTarget: (T.t, Vec2.t) => unit = "setTarget"

  type agentOptions = {
    speed?: float,
    allowDiagonals?: bool,
  }

  @send
  external addAgent: (Context.t, ~options: agentOptions=?) => Types.comp = "agent"
}
