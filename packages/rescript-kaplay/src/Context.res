open Types

@editor.completeFrom(Color)
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
  pixelDensity?: float,
  /** Padding used when adding sprites to texture atlas. */
  spriteAtlasPadding?: int,
}

@module("kaplay")
external kaplay: (~initOptions: kaplayOptions=?) => t = "default"

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

/** Get the delta time in seconds since last frame. */
@send
external dt: t => float = "dt"

/** Get the total time in seconds since beginning. */
@send
external time: t => float = "time"

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

/**
`onDraw(context, () => unit)`

 Register an event that runs every frame (~60 times per second) 
 (this is the same as onUpdate but all draw events are run after update events, 
 drawXXX() functions only work in this phase).
 */
@send
external onDraw: (t, unit => unit) => unit = "onDraw"

/**
 `onDraw(context, () => unit) => KEventController.t`

 Register an event that runs every frame (~60 times per second) 
 (this is the same as onUpdate but all draw events are run after update events, 
 drawXXX() functions only work in this phase).
 */
@send
external onDrawWithController: (t, unit => unit) => KEventController.t = "onDraw"

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
  singular?: bool,
}

@send
external loadSprite: (t, string, string, ~options: loadSpriteOptions=?) => unit = "loadSprite"

@send
external getSprite: (t, string) => Asset.t<SpriteData.t> = "getSprite"

/** Use for short sound effects, use `loadMusic` for background music. */
@send
external loadSound: (t, string, string) => unit = "loadSound"

/** Like loadSound(), but the audio is streamed and won't block loading. Use this for big audio files like background music. */
@send
external loadMusic: (t, string, string) => unit = "loadMusic"

@send
external loadBean: (t, ~name: string=?) => unit = "loadBean"

/**
 loadShader(Context.t, name, shader code)
 */
@send
external loadShader: (t, string, ~vert: string=?, ~frag: string=?) => unit = "loadShader"

@send
external loadFont: (t, string, string) => unit = "loadFont"

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

/**
 Transform a point from screen position (relative to the screen) to world position (relative to the root).

 ```res
 let mousePos = k->Context.mousePos
 let worldPos = k->Context.toWorld(mousePos)
 ```
 */
@send
external toWorld: (t, Vec2.t) => Vec2.t = "toWorld"

/** Transform a point from world position (relative to the root) to screen position (relative to the screen). */
@send
external toScreen: (t, Vec2.t) => Vec2.t = "toScreen"

/** Run the function every n seconds. */
@send
external loop: (t, float, unit => unit, ~maxLoops: int=?, ~waitFirst: bool=?) => unit = "loop"

/** Run the function every n seconds. */
@send
external loopWithController: (
  t,
  float,
  unit => unit,
  ~maxLoops: int=?,
  ~waitFirst: bool=?,
) => TimerController.t = "loop"

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

@send
external randi: (t, int, int) => int = "randi"

@send
external randf: (t, float, float) => float = "rand"

/** Convert degrees to radians */
@send
external deg2rad: (t, float) => float = "deg2rad"

/** Convert radians to degrees */
@send
external rad2deg: (t, float) => float = "rad2deg"

type playOptions = {
  /** The start time, in seconds. */
  seek?: float,
}

@send
external play: (t, string, ~options: playOptions=?) => AudioPlay.t = "play"

/** 
`tween(context, from, to, duration in seconds, setValue, easeFunc=?) => unit` 

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
) => unit = "tween"

/** 
`tween(context, from, to, duration in seconds, setValue, easeFunc=?) => TweenController.t` 

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
external tweenWithController: (
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
`setLayers(context, layers, defaultLayer)`

Define the layer names. Should be called before any objects are made.
*/
@send
external setLayers: (t, array<string>, string) => unit = "setLayers"

/**
`getLayers(context)`

Get the layer names.
*/
@send
external getLayers: t => null<array<string>> = "getLayers"

/**
`getDefaultLayer(context)`

Get the default layer name.
*/
@send
external getDefaultLayer: t => null<string> = "getDefaultLayer"

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

@send
external trigger: (t, string, string, 't) => unit = "trigger"

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

type renderProps = {
  pos?: Vec2.t,
  scale?: Vec2.t,
  angle?: float,
  color?: color,
  opacity?: float,
  fixed?: bool,
  blendMode?: blendMode,
  outline?: outline,
}

type drawSpriteInfo
external makeDrawSpriteInfoFromString: string => drawSpriteInfo = "%identity"
external makeDrawSpriteInfoFromSpriteData: SpriteData.t => drawSpriteInfo = "%identity"
external makeDrawSpriteInfoFromAsset: Asset.t<SpriteData.t> => drawSpriteInfo = "%identity"

type drawAnchor
external makeDrawAnchorFromString: string => drawAnchor = "%identity"
external makeDrawAnchorFromVec2: Vec2.t => drawAnchor = "%identity"

type drawSpriteOptions = {
  ...renderProps,
  sprite: drawSpriteInfo,
  frame?: int,
  width?: float,
  height?: float,
  tiled?: bool,
  quad?: quad,
  anchor?: drawAnchor,
}

@send
external drawSprite: (t, drawSpriteOptions) => unit = "drawSprite"

type drawTextFontInfo
external makeDrawTextFontInfoFromString: string => drawTextFontInfo = "%identity"

type drawTextOptions = {
  ...renderProps,
  text: string,
  font?: drawTextFontInfo,
  size?: float,
  align?: textAlign,
  width?: float,
  lineSpacing?: float,
  letterSpacing?: float,
  anchor?: drawAnchor,
  transform?: unknown,
  styles?: Dict.t<unknown>,
  indentAll?: bool,
}

@send
external drawText: (t, drawTextOptions) => unit = "drawText"

type drawRectOptions = {
  ...renderProps,
  width?: float,
  height?: float,
  gradient?: (color, color),
  horizontal?: bool,
  fill?: bool,
  radius?: array<float>,
  anchor?: drawAnchor,
}

@send
external drawRect: (t, drawRectOptions) => unit = "drawRect"

type drawLineOptions = {
  p1: Vec2.t,
  p2: Vec2.t,
  width?: float,
  color?: color,
  opacity?: float,
}

@send
external drawLine: (t, drawLineOptions) => unit = "drawLine"

/** Options for drawing connected lines */
type drawLinesOptions = {
  /** The points that should be connected with a line */
  pts: array<Vec2.t>,
  pos?: Vec2.t,
  color?: Types.color,
  opacity?: float,
  /** The width, or thickness of the lines */
  width?: float,
  /** The radius of each corner. Individual corner radii */
  radius?: array<float>,
  /** Line join style (default "none") */
  join?: lineJoin,
  /** Line cap style (default "none") */
  cap?: lineCap,
  /** Line bias, the position of the line relative to its center (default 0) */
  bias?: float,
  /** Maximum miter length, anything longer becomes bevel */
  miterLimit?: float,
}

@send
external drawLines: (t, drawLinesOptions) => unit = "drawLines"

type drawCurveOptions = {
  ...renderProps,
  segments?: array<float>,
  width?: float,
}

@send
external drawCurve: (t, float => Vec2.t, drawCurveOptions) => unit = "drawCurve"

type drawBezierOptions = {
  ...drawCurveOptions,
  pt1: Vec2.t,
  pt2: Vec2.t,
  pt3: Vec2.t,
  pt4: Vec2.t,
}

@send
external drawBezier: (t, drawBezierOptions) => unit = "drawBezier"

type drawTriangleOptions = {
  ...renderProps,
  p1: Vec2.t,
  p2: Vec2.t,
  p3: Vec2.t,
  fill?: bool,
  radius?: float,
}

@send
external drawTriangle: (t, drawTriangleOptions) => unit = "drawTriangle"

type drawCircleOptions = {
  pos?: Vec2.t,
  scale?: Vec2.t,
  color?: color,
  opacity?: float,
  fixed?: bool,
  blendMode?: blendMode,
  outline?: outline,
  radius: float,
  start?: float,
  fill?: bool,
  gradient?: (color, color),
  resolution?: float,
  anchor?: drawAnchor,
}

@send
external drawCircle: (t, drawCircleOptions) => unit = "drawCircle"

type drawEllipseOptions = {
  ...renderProps,
  radiusX: float,
  radiusY: float,
  start?: float,
  fill?: bool,
  gradient?: (color, color),
  resolution?: float,
  anchor?: drawAnchor,
}

@send
external drawEllipse: (t, drawEllipseOptions) => unit = "drawEllipse"

type drawPolygonOptions = {
  ...renderProps,
  pts: array<Vec2.t>,
  fill?: bool,
  indices?: array<float>,
  offset?: Vec2.t,
  radius?: array<float>,
  colors?: array<color>,
  uv?: array<Vec2.t>,
  tex?: Texture.t,
  triangulate?: bool,
}

@send
external drawPolygon: (t, drawPolygonOptions) => unit = "drawPolygon"

type drawQuadOptions = {
  ...renderProps,
  p1: Vec2.t,
}

@send
external getCursor: t => cursor = "getCursor"

@send
external setCursor: (t, cursor) => unit = "setCursor"

type includeOp = And | Or
type distanceOp = Near | Far
type hierarchy = Children | Siblings | Ancestors | Descendants

type queryOptions = {
  @as("include") include_?: array<string>,
  includeOp?: includeOp,
  exclude?: array<string>,
  excludeOp?: includeOp,
  distance?: float,
  distanceOp?: distanceOp,
  visible?: bool,
  hierarchy?: hierarchy,
}

/**
 Get a list of game objects in an advanced way.
 */
@send
external query: (t, queryOptions) => array<'gameObj> = "query"
