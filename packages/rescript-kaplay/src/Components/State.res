module Comp = (
  T: {
    type t
  },
) => {
  /**
`addState(context, initialState, stateList)` returns `Types.comp`

Finite state machine.
  */
  @send
  external addState: (Context.t, T.t, 't, array<'t>) => Types.comp = "addState"

  /**
`addStateWithTransitions(context, initialState, stateList, transitions)` returns `Types.comp`

Transitions should be an object with keys and values of 't.
  */
  @send
  external addStateWithTransitions: (Context.t, T.t, 't, array<'t>, {..}) => Types.comp =
    "addStateWithTransitions"
}
