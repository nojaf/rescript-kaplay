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
  external addState: (Context.t, T.t, string, array<string>) => Types.comp = "addState"

  /**
`addStateWithTransitions(context, initialState, stateList, transitions)` returns `Types.comp`

  */
  @send
  external addStateWithTransitions: (
    Context.t,
    T.t,
    string,
    array<string>,
    dict<string>,
  ) => Types.comp = "addStateWithTransitions"
}
