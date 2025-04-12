module Debug = {
  type t

  @send
  external log: (t, string) => unit = "log"

  @set
  external setInspect: (t, bool) => unit = "inspect"
}

type t = {debug: Debug.t}

type kaplayOptions = {
  width?: int,
  height?: int,
  global?: bool,
  background?: string,
  scale?: float,
}

@module("kaplay")
external kaplay: (~initOptions: kaplayOptions=?) => t = "default"

type tag = string

type loadSpriteAnimation = {
  from?: int,
  to?: int,
  loop?: bool,
  pingpong?: bool,
  speed?: float,
  frames?: array<int>,
}

type quad

@send
external quad: (t, int, int, int, int) => quad = "quad"

type loadSpriteOptions = {
  sliceX?: int,
  sliceY?: int,
  anims?: Dict.t<loadSpriteAnimation>,
  frames?: array<quad>,
}

@send
external loadSprite: (t, string, string, ~options: loadSpriteOptions=?) => unit = "loadSprite"

module Vec2 = {
  type t
}

@send
external vec2: (t, int, int) => Vec2.t = "vec2"

@unboxed
type key =
  | @as("left") Left
  | @as("right") Right
  | @as("up") Up
  | @as("down") Down
  | @as("space") Space
  | @as("enter") Enter

type kEventController

/**
 Hitting the key
 */
@send
external onKeyPress: (t, key => unit) => kEventController = "onKeyPress"

/**
 Holding the key down
 */
@send
external onKeyDown: (t, key => unit) => kEventController = "onKeyDown"

/**
 Lifting the key up
 */
@send
external onKeyRelease: (t, key => unit) => kEventController = "onKeyRelease"

@send
external isKeyDown: (t, key) => bool = "isKeyDown"

@send
external width: t => int = "width"

@send
external height: t => int = "height"

module Math = {
  module Shape = {
    type t
  }
}

let mathRect: (t, Vec2.t, int, int) => Math.Shape.t = %raw(`
function (k, pos, width, height) {
    return new k.Rect(pos, width, height);
}
`)

module GameObj = {
  type t

  @send
  external move: (t, int, int) => unit = "move"

  @set
  external setFrame: (t, int) => unit = "frame"

  @get
  external getFrame: t => int = "frame"

  @send
  external numFrames: t => int = "numFrames"

  @send
  external play: (t, string) => unit = "play"

  @set
  external setFlipX: (t, bool) => unit = "flipX"

  @send
  external jump: (t, float) => unit = "jump"

  @send
  external isGrounded: t => bool = "isGrounded"

  @send
  external onGround: (t, unit => unit) => kEventController = "onGround"
}

@send
external onClick: (t, tag, GameObj.t => unit) => kEventController = "onClick"

@send
external setGravity: (t, float) => unit = "setGravity"

type comp

@send
external add: (t, array<comp>) => GameObj.t = "add"

type spriteCompOptions = {
  frame?: int,
  width?: int,
  height?: int,
  anim?: string,
  singular?: bool,
}

@send
external sprite: (t, string, ~options: spriteCompOptions=?) => comp = "sprite"

@send
external pos: (t, int, int) => comp = "pos"

type areaCompOptions = {
  /** Only Rect and Polygon are supported */
  shape?: Math.Shape.t,
  offset?: Vec2.t,
}

@send
external area: (t, ~options: areaCompOptions=?) => comp = "area"

external tag: tag => comp = "%identity"

type bodyCompOpt = {isStatic?: bool}

/**
Physical body that responds to gravity. 
Requires "area" and "pos" comp. 
This also makes the object "solid".
 */
@send
external body: (t, ~options: bodyCompOpt=?) => comp = "body"

type rectCompOpt = {
  radius?: float,
  fill?: bool,
}

@send
external rect: (t, int, int, ~options: rectCompOpt=?) => comp = "rect"

/** hex value */
@send
external color: (t, string) => comp = "color"
