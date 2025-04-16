module Debug = {
  type t

  @send
  external log: (t, string) => unit = "log"

  @set
  external setInspect: (t, bool) => unit = "inspect"
}

type easeFunc = float => float
type easingMap = {linear: easeFunc}

type t = {debug: Debug.t, easings: easingMap}

type kaplayOptions = {
  width?: int,
  height?: int,
  global?: bool,
  background?: string,
  scale?: float,
  letterbox?: bool,
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
external quad: (t, float, float, float, float) => quad = "quad"

type loadSpriteOptions = {
  sliceX?: int,
  sliceY?: int,
  anims?: Dict.t<loadSpriteAnimation>,
  frames?: array<quad>,
}

@send
external loadSprite: (t, string, string, ~options: loadSpriteOptions=?) => unit = "loadSprite"

@send
external loadSound: (t, string, string) => unit = "loadSound"

/** Like loadSound(), but the audio is streamed and won't block loading. Use this for big audio files like background music. */
@send
external loadMusic: (t, string, string) => unit = "loadMusic"

module Vec2 = {
  type t = {
    mutable x: int,
    mutable y: int,
  }

  @send
  external add: (t, t) => t = "add"

  @send
  external sub: (t, t) => t = "sub"

  @send
  external scale: (t, t) => t = "scale"

  @send
  external len: t => float = "len"
}

@send
external vec2: (t, float, float) => Vec2.t = "vec2"

module Color = {
  type t
}

@send @scope("Color")
external colorFromHex: (t, string) => Color.t = "fromHex"

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

type touch

@send
external onTouchStart: (t, (Vec2.t, touch) => unit) => kEventController = "onTouchStart"

@send
external onTouchMove: (t, (Vec2.t, touch) => unit) => kEventController = "onTouchMove"

@send
external onTouchEnd: (t, (Vec2.t, touch) => unit) => kEventController = "onTouchEnd"

@send
external onUpdate: (t, unit => unit) => kEventController = "onUpdate"

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

  @get
  external getPos: t => Vec2.t = "pos"

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
  external setTarget: (t, Vec2.t) => unit = "setTarget"
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

@send
external anchorCenter: (t, @as("center") _) => comp = "anchor"

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

@send
external outline: (t, ~width: int=?, ~color: Color.t=?, ~opacity: float=?) => comp = "outline"

@send
external opacity: (t, float) => comp = "opacity"

@send
external scene: (t, string, 'a => unit) => unit = "scene"

@send
external go: (t, string, ~data: 'a=?) => unit = "go"

@send
external setCamPos: (t, Vec2.t) => unit = "setCamPos"

@send
external getCamPos: t => Vec2.t = "getCamPos"

@send
external clamp: (t, int, int, int) => int = "clamp"

type tweenController

@send
external tween: (
  t,
  ~from: 'v,
  ~to_: 'v,
  ~duration: float,
  ~setValue: 'v => unit,
  ~easeFunc: easeFunc=?,
) => tweenController = "tween"

@send
external setFullscreen: (t, bool) => unit = "setFullscreen"

type levelOptions = {
  tileWidth?: int,
  tileHeight?: int,
  tiles: Dict.t<unit => array<comp>>,
}

module Level = {
  type t

  @send
  external spawn: (t, array<comp>, Vec2.t) => GameObj.t = "spawn"
}

@send
external addLevel: (t, array<string>, levelOptions) => Level.t = "addLevel"

type tileOptions = {
  isObstacle?: bool,
  cost?: int,
  offset?: Vec2.t,
}

@send
external tile: (t, ~options: tileOptions=?) => comp = "tile"

type agentOptions = {
  speed?: float,
  allowDiagonals?: bool,
}

@send
external agent: (t, ~options: agentOptions=?) => comp = "agent"

type getOptions = {
  recursive?: bool,
  liveUpdate?: bool,
}

@send
external getGameObjects: (t, tag, ~options: getOptions=?) => array<GameObj.t> = "get"

module AudioPlay = {
  type t
}

type playOptions = {
  /** The start time, in seconds. */
  seek?: float,
}

@send
external play: (t, string, ~options: playOptions=?) => AudioPlay.t = "play"
