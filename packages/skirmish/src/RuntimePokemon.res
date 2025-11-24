open Kaplay

/***
 This is a runtime representation of a Pokemon game object.
 It exposes the raw Kaplay game object API.
 We use this to avoid coupling the Pokemon module and any potential move module.
 */

type t<'child> = {
  direction: Vec2.t,
  /// Note that this is addChild in the GameObjRaw module, but at runtime is it is `add`
  add: array<Types.comp> => 'child,
  use: Types.comp => unit,
  unuse: string => unit,
  width: float,
  height: float,
}
