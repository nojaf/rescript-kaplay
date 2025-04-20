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
  anim?: string,
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
    mutable x: float,
    mutable y: float,
  }

  @send
  external add: (t, t) => t = "add"

  @send
  external sub: (t, t) => t = "sub"

  @send
  external scale: (t, t) => t = "scale"

  @send
  external len: t => float = "len"

  @send
  external unit: t => t = "unit"

  @send
  external lerp: (t, t, float) => t = "lerp"

  @send
  external dist: (t, t) => float = "dist"
}

@send @scope("Vec2")
external vec2Zero: t => Vec2.t = "ZERO"

@send @scope("Vec2")
external vec2One: t => Vec2.t = "ONE"

@send @scope("Vec2")
external vec2Left: t => Vec2.t = "LEFT"

@send @scope("Vec2")
external vec2Right: t => Vec2.t = "RIGHT"

@send @scope("Vec2")
external vec2Up: t => Vec2.t = "UP"

@send @scope("Vec2")
external vec2Down: t => Vec2.t = "DOWN"

@send
external vec2: (t, float, float) => Vec2.t = "vec2"

@send
external vec2Diagnoal: (t, float) => Vec2.t = "vec2"

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

/** Register an event that runs when all assets finished loading. */
@send
external onLoad: (t, unit => unit) => unit = "onLoad"

module TimerControllerImpl = (
  T: {
    type t
  },
) => {
  @send
  external cancel: T.t => unit = "cancel"

  @send
  external onEnd: (T.t, unit => unit) => unit = "onEnd"

  @send
  external then: (T.t, unit => unit) => T.t = "then"
}

module TimerController = {
  type t = {mutable paused: bool}

  include TimerControllerImpl({
    type t = t
  })
}

/** Run the function every n seconds. */
@send
external loop: (t, float, unit => unit, ~maxLoops: int=?, ~waitFirst: bool=?) => TimerController.t =
  "loop"

@send
external wait: (t, float, unit => unit) => TimerController.t = "wait"

@send
external width: t => int = "width"

@send
external height: t => int = "height"

/** Get the delta time since last frame. */
@send
external dt: t => float = "dt"

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

/** center, radius */
let mathCircle: (t, Vec2.t, float) => Math.Shape.t = %raw(`
function (k, center, radius) {
    return new k.Circle(center, radius);
}
`)

let mathPolygon: (t, array<Vec2.t>) => Math.Shape.t = %raw(`
function (k,  points) {
    return new k.Polygon(points);
}
`)

@send
external randi: (t, int, int) => int = "randi"

type comp

module Collision = {
  type t
}

type gameObj = {
  id: int,
  // PosComp
  mutable pos: Vec2.t,
  // SpriteComp
  mutable frame: int,
  mutable flipX: bool,
  mutable width: float,
  mutable height: float,
  // ColorComp
  mutable color: Color.t,
  // OpacityComp
  mutable opacity: float,
}

module GameObjImpl = (
  T: {
    type t
  },
) => {
  @send
  external move: (T.t, Vec2.t) => unit = "move"

  @send
  external numFrames: T.t => int = "numFrames"

  @send
  external play: (T.t, string) => unit = "play"

  @send
  external jump: (T.t, float) => unit = "jump"

  @send
  external isGrounded: T.t => bool = "isGrounded"

  @send
  external onGround: (T.t, unit => unit) => kEventController = "onGround"

  /**
    Hitting the key
 */
  @send
  external onKeyPress: (T.t, key => unit) => kEventController = "onKeyPress"

  /**
    Holding the key down
 */
  @send
  external onKeyDown: (T.t, key => unit) => kEventController = "onKeyDown"

  /**
    Lifting the key up
 */
  @send
  external onKeyRelease: (T.t, key => unit) => kEventController = "onKeyRelease"

  /** Part of the agent comp  */
  @send
  external setTarget: (T.t, Vec2.t) => unit = "setTarget"

  /** Part of the sentry comp */
  @send
  external onObjectsSpotted: (T.t, array<gameObj> => unit) => kEventController = "onObjectsSpotted"

  @send
  external onCollide: (T.t, tag, (gameObj, Collision.t) => unit) => kEventController = "onCollide"

  @send
  external onCollideEnd: (T.t, tag, gameObj => unit) => kEventController = "onCollideEnd"

  @send
  external onUpdate: (T.t, unit => unit) => kEventController = "onUpdate"

  @send
  external add: (T.t, array<comp>) => t = "add"

  @send
  external destroy: T.t => unit = "destroy"

  @send
  external hurt: (T.t, int) => unit = "hurt"

  @send
  external heal: (T.t, int) => unit = "heal"

  @send
  external hp: T.t => int = "hp"

  @send
  external setHP: (T.t, int) => unit = "setHP"

  @send
  external onHurt: (T.t, int => unit) => kEventController = "onHurt"

  @send
  external onHeal: (T.t, (~amount: int=?) => unit) => kEventController = "onHeal"

  @send
  external onDeath: (T.t, unit => unit) => kEventController = "onDeath"

  @send
  external get: (T.t, tag) => array<gameObj> = "get"

  @send
  external untag: (T.t, tag) => unit = "untag"
}

module GameObj = {
  type t = gameObj

  include GameObjImpl({
    type t = gameObj
  })
}

/** Definition of a custom component */
type component<'t> = {
  id: string,
  update?: @this ('t => unit),
  require?: array<string>,
  add?: @this ('t => unit),
  draw?: @this ('t => unit),
  destroy?: @this ('t => unit),
  inspect?: @this ('t => unit),
}

external customComponent: component<'t> => comp = "%identity"

@send
external onClick: (t, tag, GameObj.t => unit) => kEventController = "onClick"

@send
external setGravity: (t, float) => unit = "setGravity"

@send
external destroy: (t, GameObj.t) => unit = "destroy"

module AudioPlay = {
  type t
}

type playOptions = {
  /** The start time, in seconds. */
  seek?: float,
}
@send
external play: (t, string, ~options: playOptions=?) => AudioPlay.t = "play"

@send
external add: (t, array<comp>) => GameObj.t = "add"

type spriteCompOptions = {
  frame?: int,
  width?: int,
  height?: int,
  anim?: string,
  singular?: bool,
  flipX?: bool,
  flipY?: bool,
}

type getOptions = {
  recursive?: bool,
  liveUpdate?: bool,
}

@send
external getGameObjects: (t, tag, ~options: getOptions=?) => array<GameObj.t> = "get"

@send
external sprite: (t, string, ~options: spriteCompOptions=?) => comp = "sprite"

@send
external pos: (t, int, int) => comp = "pos"

@send
external posVec2: (t, Vec2.t) => comp = "pos"

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

type bodyOptions = {isStatic?: bool}

/**
Physical body that responds to gravity.
Requires "area" and "pos" comp.
This also makes the object "solid".
 */
@send
external body: (t, ~options: bodyOptions=?) => comp = "body"

type rectOptions = {
  radius?: float,
  fill?: bool,
}

@send
external rect: (t, int, int, ~options: rectOptions=?) => comp = "rect"

type circleOptions = {fill?: bool}

@send
external circle: (t, int, ~options: circleOptions=?) => comp = "circle"

/** hex value */
@send
external color: (t, Color.t) => comp = "color"

@send
external outline: (t, ~width: int=?, ~color: Color.t=?, ~opacity: float=?) => comp = "outline"

/** Value between 0 and 1 */
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

@send
external clampFloat: (t, float, float, float) => float = "clampFloat"

module TweenController = {
  type t = {mutable paused: bool}

  include TimerControllerImpl({
    type t = t
  })

  @send
  external finish: t => unit = "finish"
}

@send
external tween: (
  t,
  ~from: 'v,
  ~to_: 'v,
  ~duration: float,
  ~setValue: 'v => unit,
  ~easeFunc: easeFunc=?,
) => TweenController.t = "tween"

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

type sentryOptions = {
  direction?: Vec2.t,
  fieldOfView?: float,
  lineOfSight?: bool,
  raycastExclude?: array<string>,
  checkFrequency?: float,
}

@send
external sentry: (t, array<GameObj.t>, ~options: sentryOptions=?) => comp = "sentry"

type textAlign =
  | @as("left") Left
  | @as("center") Center
  | @as("right") Right

type textOptions = {
  size?: float,
  font?: string,
  width?: int,
  align?: textAlign,
  lineSpacing?: float,
  letterSpacing?: float,
}

@send
external move: (t, Vec2.t, float) => comp = "move"

type offscreenOptions = {
  hide?: bool,
  pause?: bool,
  destroy?: bool,
  distance?: int,
}

@send
external offscreen: (t, ~options: offscreenOptions=?) => comp = "offscreen"

@send
external text: (t, string, ~options: textOptions=?) => comp = "text"

@send
external health: (t, int, ~maxHp: int=?) => comp = "health"

@send
external z: (t, int) => comp = "z"
