module Comp = (
  T: {
    type t
  },
) => {
  /**
   `onExitScreen(context, handler)` register an event that runs when object goes out of view.
   */
  @send
  external onExitScreen: (T.t, unit => unit) => unit = "onExitScreen"

  type offscreenOptions = {
    hide?: bool,
    pause?: bool,
    destroy?: bool,
    distance?: int,
  }

  @send
  external addOffScreen: (Context.t, ~options: offscreenOptions=?) => Types.comp = "offscreen"
}
