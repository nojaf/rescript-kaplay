module Comp = (
  T: {
    type t
  },
) => {
  open Types

  @get
  external getId: T.t => int = "id"

  /**
   Check if game object has a certain component.
   */
  @send
  external has: (T.t, string) => bool = "has"

  /**
    Hitting the key
 */
  @send
  external onKeyPress: (T.t, key => unit) => KEventController.t = "onKeyPress"

  /**
    Holding the key down
 */
  @send
  external onKeyDown: (T.t, key => unit) => KEventController.t = "onKeyDown"

  /**
    Lifting the key up
 */
  @send
  external onKeyRelease: (T.t, key => unit) => KEventController.t = "onKeyRelease"

  @send
  external onUpdate: (T.t, unit => unit) => unit = "onUpdate"

  @send
  external onUpdateWithController: (T.t, unit => unit) => KEventController.t = "onUpdate"

  /**
  Add a game object from an array of components.
 */
  @send
  external addChild: (T.t, array<comp>) => 't = "add"

  @send
  external destroy: T.t => unit = "destroy"

  @send
  external get: (T.t, 'tag) => array<'t> = "get"

  @send
  external untag: (T.t, 'tag) => unit = "untag"

  @send
  external onDestroy: (T.t, unit => unit) => KEventController.t = "onDestroy"

  /**
 Trigger a custom event on this game object.
 */
  @send
  external trigger: (T.t, string, 'arg) => unit = "trigger"

  /**
 `use(t, comp)` add a game component to this game object.
 Useful for adding conditional components after creation.
 */
  external use: (T.t, comp) => unit = "use"
}
