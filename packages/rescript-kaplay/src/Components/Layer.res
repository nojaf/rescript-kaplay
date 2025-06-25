module Comp = (
  T: {
    type t
  },
) => {
  /**
`layerIndex(layer)`

Get the index of the current layer the object is assigned to. Will always be `null` if the game doesn't use layers.
  */
  @send
  external layerIndex: T.t => null<int> = "layerIndex"

  /**
Get the name of the current layer the object is assigned to. Will always be `null` if the game doesn't use layers.
 */
  @send
  external getLayer: T.t => null<string> = "layer"

  /**
Set the name of the layer the object should be assigned to. Throws an error if the game uses layers and the requested layer wasn't defined.
 */
  @send
  external setLayer: (T.t, string) => unit = "layer"

  /**
`layer(context, layerName)`

Determines the layer for objects. Object will be drawn on top if the layer index is higher.
  */
  @send
  external addLayer: (Context.t, string) => Types.comp = "layer"
}
