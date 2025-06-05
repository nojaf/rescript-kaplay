/**
 Creating a custom component is a way to extend the Kaplay engine with your own custom logic.
 See https://v4000.kaplayjs.com/guides/custom_components/

 Be aware that 
 */
type t<'gameObj> = {
  id: string,
  /** What other comps this comp depends on. */
  require?: array<string>,
  /** Event that runs when host game obj is added to scene. */
  add?: @this ('gameObj => unit),
  /** Event that runs at a fixed frame rate. */
  fixedUpdate?: @this ('gameObj => unit),
  /** Event that runs every frame. */
  update?: @this ('gameObj => unit),
  /** Event that runs every frame after update. */
  draw?: @this ('gameObj => unit),
  /** Event that runs when obj is removed from scene. */
  destroy?: @this ('gameObj => unit),
  /** Debug info for inspect mode. */
  inspect?: @this ('gameObj => Null.t<string>),
  /** Draw debug info in inspect mode */
  drawInspect?:@this ('gameObj => unit),
}

external make: t<'gameObj> => Types.comp = "%identity"
