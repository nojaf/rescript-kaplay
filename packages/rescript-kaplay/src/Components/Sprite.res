module Comp = (
  T: {
    type t
  },
) => {
  @send
  external numFrames: T.t => int = "numFrames"

  @send
  external play: (T.t, string) => unit = "play"

  @get
  external getSprite: T.t => string = "sprite"

  @set
  external setSprite: (T.t, string) => unit = "sprite"

  @get
  external getFrame: T.t => int = "frame"

  @set
  external setFrame: (T.t, int) => unit = "frame"

  @get
  external getAnimFrame: T.t => int = "animFrame"

  @set
  external setAnimFrame: (T.t, int) => unit = "animFrame"

  @get
  external getAnimSpeed: T.t => float = "animSpeed"

  @set
  external setAnimSpeed: (T.t, float) => unit = "animSpeed"

  @get
  external getFlipX: T.t => bool = "flipX"

  @set
  external setFlipX: (T.t, bool) => unit = "flipX"

  @get
  external getWidth: T.t => float = "width"

  @set
  external setWidth: (T.t, float) => unit = "width"

  @get
  external getHeight: T.t => float = "height"

  @set
  external setHeight: (T.t, float) => unit = "height"

  type spriteCompOptions = {
    frame?: int,
    width?: float,
    height?: float,
    anim?: string,
    singular?: bool,
    flipX?: bool,
    flipY?: bool,
  }
  @send
  external addSprite: (Context.t, string, ~options: spriteCompOptions=?) => Types.comp = "sprite"
}
