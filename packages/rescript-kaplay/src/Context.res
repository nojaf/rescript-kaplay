type easeFunc = float => float
type easingMap = {linear: easeFunc}

type t = {debug: Debug.t, easings: easingMap}

type htmlCanvasElement

/**
Initialize KAPLAY context. The starting point of all KAPLAY games.
*/
type kaplayOptions = {
  width?: int,
  height?: int,
  global?: bool,
  background?: string,
  scale?: float,
  letterbox?: bool,
  canvas?: htmlCanvasElement,
  crisp?: bool,
}

@module("kaplay")
external kaplay: (~initOptions: kaplayOptions=?) => t = "default"

open Types

@send
external add: (t, array<comp>) => 't = "add"

external tag: string => comp = "%identity"

type getOptions = {
  recursive?: bool,
  liveUpdate?: bool,
}

@send
external getGameObjects: (t, string, ~options: getOptions=?) => array<'t> = "get"

@send
external scene: (t, string, 'a => unit) => unit = "scene"

@send
external go: (t, string, ~data: 'a=?) => unit = "go"

/**
`go(context, sceneName, ~data=?)`

Go to a scene with data passed to the scene.
*/
@send
external goWithData: (t, string, 'a) => unit = "go"

@send
external setCamPos: (t, Vec2.t) => unit = "setCamPos"

@send
external getCamPos: t => Vec2.t = "getCamPos"

@send
external clamp: (t, int, int, int) => int = "clamp"

@send
external clampFloat: (t, float, float, float) => float = "clamp"

/**
`wait(context, seconds, callback)`

Run the function after n seconds.
*/
@send
external wait: (t, float, unit => unit) => unit = "wait"

/**
`wait(context, seconds, callback)`

Run the function after n seconds.
*/
@send
external waitWithController: (t, float, unit => unit) => TimerController.t = "wait"

/** Get the delta time in seconds since last frame. */
@send
external dt: t => float = "dt"

@send @scope("Color")
external colorFromHex: (t, string) => color = "fromHex"

@send
external onClick: (t, unit => unit) => unit = "onClick"

@send
external onClickWithController: (t, unit => unit) => KEventController.t = "onClick"

@send
external onClickWithTag: (t, string, 't => unit) => KEventController.t = "onClick"

/**
 Hitting the key
 */
@send
external onKeyPress: (t, key => unit) => unit = "onKeyPress"

/**
 Hitting the key
 */
@send
external onKeyPressWithController: (t, key => unit) => KEventController.t = "onKeyPress"

/**
 Holding the key down
 */
@send
external onKeyDown: (t, key => unit) => unit = "onKeyDown"

/**
 Holding the key down
 */
@send
external onKeyDownWithController: (t, key => unit) => KEventController.t = "onKeyDown"

/**
 Lifting the key up
 */
@send
external onKeyRelease: (t, key => unit) => unit = "onKeyRelease"

/**
 Lifting the key up
 */
@send
external onKeyReleaseWithController: (t, key => unit) => KEventController.t = "onKeyRelease"

@send
external isKeyDown: (t, key) => bool = "isKeyDown"

@send
external onTouchStart: (t, (Vec2.t, touch) => unit) => unit = "onTouchStart"

@send
external onTouchStartWithController: (t, (Vec2.t, touch) => unit) => KEventController.t =
  "onTouchStart"

@send
external onTouchMove: (t, (Vec2.t, touch) => unit) => unit = "onTouchMove"

@send
external onTouchMoveWithController: (t, (Vec2.t, touch) => unit) => KEventController.t =
  "onTouchMove"

@send
external onTouchEnd: (t, (Vec2.t, touch) => unit) => unit = "onTouchEnd"

@send
external onTouchEndWithController: (t, (Vec2.t, touch) => unit) => KEventController.t = "onTouchEnd"

@send
external onUpdate: (t, unit => unit) => unit = "onUpdate"

@send
external onUpdateWithController: (t, unit => unit) => KEventController.t = "onUpdate"

/** Register an event that runs when all assets finished loading. */
@send
external onLoad: (t, unit => unit) => unit = "onLoad"

@send
external setGravity: (t, float) => unit = "setGravity"

@send
external destroy: (t, 't) => unit = "destroy"

@send
external quad: (t, float, float, float, float) => quad = "quad"

type loadSpriteAnimation = {
  from?: int,
  to?: int,
  loop?: bool,
  pingpong?: bool,
  speed?: float,
  frames?: array<int>,
}

type loadSpriteOptions = {
  sliceX?: int,
  sliceY?: int,
  anims?: Dict.t<loadSpriteAnimation>,
  anim?: string,
  frames?: array<quad>,
}

@send
external loadSprite: (t, string, string, ~options: loadSpriteOptions=?) => unit = "loadSprite"

/** Use for short sound effects, use `loadMusic` for background music. */
@send
external loadSound: (t, string, string) => unit = "loadSound"

/** Like loadSound(), but the audio is streamed and won't block loading. Use this for big audio files like background music. */
@send
external loadMusic: (t, string, string) => unit = "loadMusic"

@send
external loadBean: (t, ~name: string=?) => unit = "loadBean"

@get @scope("Vec2")
external vec2Zero: t => Vec2.t = "ZERO"

@get @scope("Vec2")
external vec2One: t => Vec2.t = "ONE"

@get @scope("Vec2")
external vec2Left: t => Vec2.t = "LEFT"

@get @scope("Vec2")
external vec2Right: t => Vec2.t = "RIGHT"

@get @scope("Vec2")
external vec2Up: t => Vec2.t = "UP"

@get @scope("Vec2")
external vec2Down: t => Vec2.t = "DOWN"

@send
external vec2: (t, float, float) => Vec2.t = "vec2"

@send
external vec2FromXY: (t, float) => Vec2.t = "vec2"

@send
external center: t => Vec2.t = "center"

@send
external width: t => float = "width"

@send
external height: t => float = "height"

/** Run the function every n seconds. */
@send
external loop: (t, float, unit => unit, ~maxLoops: int=?, ~waitFirst: bool=?) => TimerController.t =
  "loop"

let mathRect: (t, Vec2.t, float, float) => Math.Shape.t = %raw(`
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

@send
external randf: (t, float, float) => float = "rand"

external customComponent: component<'t> => comp = "%identity"

type playOptions = {
  /** The start time, in seconds. */
  seek?: float,
}

@send
external play: (t, string, ~options: playOptions=?) => AudioPlay.t = "play"

/** 
`tween(context, from, to, duration in seconds, setValue, easeFunc=?)` 

Useful to change a property of a Game Object over time.
```ReScript
k
->Context.tween(
  ~from=-15.,
  ~to_=0.,
  ~duration=0.5,
  ~setValue=Bird.setAngle(bird, ...),
)
```
*/
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
external addLevel: (t, array<string>, levelOptions) => Level.t = "addLevel"

@send
external setBackground: (t, color) => unit = "setBackground"

/**
`on(context, event, tag, (gameObject, arg) => unit)`

Register an event on all game objs with certain tag.
*/
@send
external on: (t, ~event: string, ~tag: string, ('t, 'arg) => unit) => unit = "on"

/**
`on(context, event, tag, (gameObject, arg) => unit)`

Register an event on all game objs with certain tag.
*/
@send
external onWithController: (
  t,
  ~event: string,
  ~tag: string,
  ('t, 'arg) => unit,
) => KEventController.t = "on"

/**
 Get current mouse position (without camera transform).
 */
@send
external mousePos: t => Vec2.t = "mousePos"

/**
 Register an event that runs whenever user presses a mouse button.
 */
@send
external onMousePress: (t, mouseButton => unit) => unit = "onMousePress"

/**
 Register an event that runs whenever user presses a mouse button.
 */
@send
external onMousePressWithController: (t, mouseButton => unit) => KEventController.t = "onMousePress"

/**
`onMouseMove(context, (pos, delta) => unit)`

Register an event that runs whenever user moves the mouse.
*/
@send
external onMouseMove: (t, (Vec2.t, Vec2.t) => unit) => unit = "onMouseMove"

/**
`onMouseMove(context, (pos, delta) => KEventController.t)`

Register an event that runs whenever user moves the mouse.
*/
@send
external onMouseMoveWithController: (t, (Vec2.t, Vec2.t) => unit) => KEventController.t =
  "onMouseMove"

/**
 Register an event that runs whenever user releases a mouse button.
 */
@send
external onMouseRelease: (t, mouseButton => unit) => unit = "onMouseRelease"

/**
 Register an event that runs whenever user releases a mouse button.
 */
@send
external onMouseReleaseWithController: (t, mouseButton => unit) => KEventController.t =
  "onMouseRelease"
