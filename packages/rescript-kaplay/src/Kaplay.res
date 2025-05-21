module Debug = {
  type t

  @send
  external log: (t, 't) => unit = "log"

  @set
  external setInspect: (t, bool) => unit = "inspect"
}

type easeFunc = float => float
type easingMap = {linear: easeFunc}

type kaplayContext = {debug: Debug.t, easings: easingMap}

type kaplayOptions = {
  width?: int,
  height?: int,
  global?: bool,
  background?: string,
  scale?: float,
  letterbox?: bool,
}

@module("kaplay")
external kaplay: (~initOptions: kaplayOptions=?) => kaplayContext = "default"

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
external quad: (kaplayContext, float, float, float, float) => quad = "quad"

type loadSpriteOptions = {
  sliceX?: int,
  sliceY?: int,
  anims?: Dict.t<loadSpriteAnimation>,
  anim?: string,
  frames?: array<quad>,
}

@send
external loadSprite: (kaplayContext, string, string, ~options: loadSpriteOptions=?) => unit =
  "loadSprite"

@send
external loadSound: (kaplayContext, string, string) => unit = "loadSound"

/** Like loadSound(), but the audio is streamed and won't block loading. Use this for big audio files like background music. */
@send
external loadMusic: (kaplayContext, string, string) => unit = "loadMusic"

@send
external loadBean: (kaplayContext, ~name: string=?) => unit = "loadBean"

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

  @send
  external dot: (t, t) => float = "dot"
}

@get @scope("Vec2")
external vec2Zero: kaplayContext => Vec2.t = "ZERO"

@get @scope("Vec2")
external vec2One: kaplayContext => Vec2.t = "ONE"

@get @scope("Vec2")
external vec2Left: kaplayContext => Vec2.t = "LEFT"

@get @scope("Vec2")
external vec2Right: kaplayContext => Vec2.t = "RIGHT"

@get @scope("Vec2")
external vec2Up: kaplayContext => Vec2.t = "UP"

@get @scope("Vec2")
external vec2Down: kaplayContext => Vec2.t = "DOWN"

@send
external vec2: (kaplayContext, float, float) => Vec2.t = "vec2"

@send
external vec2Diagnoal: (kaplayContext, float) => Vec2.t = "vec2"

@send
external center: kaplayContext => Vec2.t = "center"

module Color = {
  type t
}

@send @scope("Color")
external colorFromHex: (kaplayContext, string) => Color.t = "fromHex"

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
external onKeyPress: (kaplayContext, key => unit) => kEventController = "onKeyPress"

/**
 Holding the key down
 */
@send
external onKeyDown: (kaplayContext, key => unit) => kEventController = "onKeyDown"

/**
 Lifting the key up
 */
@send
external onKeyRelease: (kaplayContext, key => unit) => kEventController = "onKeyRelease"

@send
external isKeyDown: (kaplayContext, key) => bool = "isKeyDown"

type touch

@send
external onTouchStart: (kaplayContext, (Vec2.t, touch) => unit) => kEventController = "onTouchStart"

@send
external onTouchMove: (kaplayContext, (Vec2.t, touch) => unit) => kEventController = "onTouchMove"

@send
external onTouchEnd: (kaplayContext, (Vec2.t, touch) => unit) => kEventController = "onTouchEnd"

@send
external onUpdate: (kaplayContext, unit => unit) => kEventController = "onUpdate"

/** Register an event that runs when all assets finished loading. */
@send
external onLoad: (kaplayContext, unit => unit) => unit = "onLoad"

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
external loop: (
  kaplayContext,
  float,
  unit => unit,
  ~maxLoops: int=?,
  ~waitFirst: bool=?,
) => TimerController.t = "loop"

@send
external wait: (kaplayContext, float, unit => unit) => TimerController.t = "wait"

@send
external width: kaplayContext => float = "width"

@send
external height: kaplayContext => float = "height"

/** Get the delta time since last frame. */
@send
external dt: kaplayContext => float = "dt"

module Math = {
  module Shape = {
    type t
  }
}

let mathRect: (kaplayContext, Vec2.t, float, float) => Math.Shape.t = %raw(`
function (k, pos, width, height) {
    return new k.Rect(pos, width, height);
}
`)

/** center, radius */
let mathCircle: (kaplayContext, Vec2.t, float) => Math.Shape.t = %raw(`
function (k, center, radius) {
    return new k.Circle(center, radius);
}
`)

let mathPolygon: (kaplayContext, array<Vec2.t>) => Math.Shape.t = %raw(`
function (k,  points) {
    return new k.Polygon(points);
}
`)

@send
external randi: (kaplayContext, int, int) => int = "randi"

@send
external randf: (kaplayContext, float, float) => float = "rand"

type comp

module Collision = {
  type t
}

module GameObjRaw = (
  T: {
    type t
  },
) => {
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

  @send
  external onUpdate: (T.t, unit => unit) => kEventController = "onUpdate"

  @send
  external add: (T.t, array<comp>) => 't = "add"

  @send
  external destroy: T.t => unit = "destroy"

  @send
  external get: (T.t, 'tag) => array<'t> = "get"

  @send
  external untag: (T.t, 'tag) => unit = "untag"

  @send
  external onDestroy: (T.t, unit => unit) => kEventController = "onDestroy"
}

module PosComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @send
  external move: (T.t, Vec2.t) => unit = "move"

  @send
  external worldPos: T.t => Vec2.t = "worldPos"

  @send
  external setWorldPos: (T.t, Vec2.t) => unit = "worldPos"

  @get
  external getPos: T.t => Vec2.t = "pos"

  @set
  external setPos: (T.t, Vec2.t) => unit = "pos"
  @send
  external addPos: (kaplayContext, float, float) => comp = "pos"

  @send
  external addPosFromVec2: (kaplayContext, Vec2.t) => comp = "pos"
}

module RectComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })
  type rectOptions = {
    radius?: float,
    fill?: bool,
  }

  @send
  external addRect: (kaplayContext, float, float, ~options: rectOptions=?) => comp = "rect"
}

module CircleComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  type circleOptions = {fill?: bool}

  @send
  external addCircle: (kaplayContext, float, ~options: circleOptions=?) => comp = "circle"
}

module ColorComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @get
  external getColor: T.t => Color.t = "color"

  @set
  external setColor: (T.t, Color.t) => unit = "color"

  /** hex value */
  @send
  external addColor: (kaplayContext, Color.t) => comp = "color"
}

module OutlineComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @send
  external addOutline: (
    kaplayContext,
    ~width: int=?,
    ~color: Color.t=?,
    ~opacity: float=?,
  ) => comp = "outline"
}

module OpacityComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @get
  external getOpacity: T.t => float = "opacity"

  @set
  external setOpacity: (T.t, float) => unit = "opacity"

  /** Value between 0 and 1 */
  @send
  external addOpacity: (kaplayContext, float) => comp = "opacity"
}

module SpriteComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

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
  external addSprite: (kaplayContext, string, ~options: spriteCompOptions=?) => comp = "sprite"
}

module AnchorComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @send
  external addAnchorCenter: (kaplayContext, @as("center") _) => comp = "anchor"
}

module BodyComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @send
  external jump: (T.t, float) => unit = "jump"

  @send
  external isGrounded: T.t => bool = "isGrounded"

  @send
  external onGround: (T.t, unit => unit) => kEventController = "onGround"

  type bodyOptions = {isStatic?: bool}

  /**
Physical body that responds to gravity.
Requires "area" and "pos" comp.
This also makes the object "solid".
 */
  @send
  external addBody: (kaplayContext, ~options: bodyOptions=?) => comp = "body"
}

module AgentComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  /** Part of the agent comp  */
  @send
  external setTarget: (T.t, Vec2.t) => unit = "setTarget"

  type agentOptions = {
    speed?: float,
    allowDiagonals?: bool,
  }

  @send
  external addAgent: (kaplayContext, ~options: agentOptions=?) => comp = "agent"
}

module SentryComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  /** Part of the sentry comp */
  @send
  external onObjectsSpotted: (T.t, array<'t> => unit) => kEventController = "onObjectsSpotted"

  type sentryOptions = {
    direction?: Vec2.t,
    fieldOfView?: float,
    lineOfSight?: bool,
    raycastExclude?: array<string>,
    checkFrequency?: float,
  }

  @send
  external make: (kaplayContext, array<'t>, ~options: sentryOptions=?) => comp = "sentry"
}

module AreaComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @send
  external onCollide: (T.t, string, ('t, Collision.t) => unit) => kEventController = "onCollide"

  @send
  external onCollideEnd: (T.t, 'tag, 't => unit) => kEventController = "onCollideEnd"

  @send
  external hasPoint: (T.t, Vec2.t) => bool = "hasPoint"

  type areaCompOptions = {
    /** Only Rect and Polygon are supported */
    shape?: Math.Shape.t,
    offset?: Vec2.t,
    scale?: float,
  }

  @send
  external addArea: (kaplayContext, ~options: areaCompOptions=?) => comp = "area"
}

module HealthComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

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
  external make: (kaplayContext, int, ~maxHp: int=?) => comp = "health"
}

module TextComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @get
  external getText: T.t => string = "text"

  @set
  external setText: (T.t, string) => unit = "text"

  type textAlign =
    | @as("left") Left
    | @as("center") Center
    | @as("right") Right

  type textOptions = {
    size?: float,
    font?: string,
    width?: float,
    align?: textAlign,
    lineSpacing?: float,
    letterSpacing?: float,
  }

  @send
  external addText: (kaplayContext, string, ~options: textOptions=?) => comp = "text"
}

module OffScreenComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })
  type offscreenOptions = {
    hide?: bool,
    pause?: bool,
    destroy?: bool,
    distance?: int,
  }

  @send
  external make: (kaplayContext, ~options: offscreenOptions=?) => comp = "offscreen"
}

module MoveComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  /**
 Move towards a direction infinitely, and destroys when it leaves game view.
 */
  @send
  external make: (kaplayContext, Vec2.t, float) => comp = "move"
}

module TileComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  type tileOptions = {
    isObstacle?: bool,
    cost?: int,
    offset?: Vec2.t,
  }

  @send
  external addTile: (kaplayContext, ~options: tileOptions=?) => comp = "tile"
}

module ZComp = (
  T: {
    type t
  },
) => {
  include GameObjRaw({
    type t = T.t
  })

  @send
  external addZ: (kaplayContext, int) => comp = "z"
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
external onClick: (kaplayContext, unit => unit) => kEventController = "onClick"

@send
external onClickWithTag: (kaplayContext, string, 't => unit) => kEventController = "onClick"

@send
external setGravity: (kaplayContext, float) => unit = "setGravity"

@send
external destroy: (kaplayContext, 't) => unit = "destroy"

module AudioPlay = {
  type t
}

type playOptions = {
  /** The start time, in seconds. */
  seek?: float,
}

@send
external play: (kaplayContext, string, ~options: playOptions=?) => AudioPlay.t = "play"

@send
external add: (kaplayContext, array<comp>) => 't = "add"

type getOptions = {
  recursive?: bool,
  liveUpdate?: bool,
}

@send
external getGameObjects: (kaplayContext, string, ~options: getOptions=?) => array<'t> = "get"

external tag: string => comp = "%identity"

@send
external scene: (kaplayContext, string, 'a => unit) => unit = "scene"

@send
external go: (kaplayContext, string, ~data: 'a=?) => unit = "go"

@send
external setCamPos: (kaplayContext, Vec2.t) => unit = "setCamPos"

@send
external getCamPos: kaplayContext => Vec2.t = "getCamPos"

@send
external clamp: (kaplayContext, int, int, int) => int = "clamp"

@send
external clampFloat: (kaplayContext, float, float, float) => float = "clampFloat"

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
  kaplayContext,
  ~from: 'v,
  ~to_: 'v,
  ~duration: float,
  ~setValue: 'v => unit,
  ~easeFunc: easeFunc=?,
) => TweenController.t = "tween"

@send
external setFullscreen: (kaplayContext, bool) => unit = "setFullscreen"

type levelOptions = {
  tileWidth?: float,
  tileHeight?: float,
  tiles: Dict.t<unit => array<comp>>,
}

module Level = {
  type t

  @send
  external spawn: (t, array<comp>, Vec2.t) => 't = "spawn"
}

@send
external addLevel: (kaplayContext, array<string>, levelOptions) => Level.t = "addLevel"
