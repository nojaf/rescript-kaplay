type comp

@unboxed
type key =
  | @as("left") Left
  | @as("right") Right
  | @as("up") Up
  | @as("down") Down
  | @as("space") Space
  | @as("enter") Enter

type color

type quad

type touch

@unboxed
type mouseButton =
  | @as("left") Left
  | @as("right") Right
  | @as("middle") Middle
  | @as("back") Back
  | @as("forward") Forward

@unboxed
type timeDirection =
  | @as("forward") Forward
  | @as("reverse") Reverse
  | @as("ping-pong") PingPong

type easeFunc = float => float
type easingMap = {linear: easeFunc}

type interpolation =
  | @as("none") None
  | @as("linear") Linear
  | @as("slerp") Slerp
  | @as("spline") Spline

/** Line join style for drawing operations */
@unboxed
type lineJoin =
  | @as("none") None
  | @as("round") Round
  | @as("bevel") Bevel
  | @as("miter") Miter

/** Line cap style for drawing operations */
@unboxed
type lineCap =
  | @as("none") None
  | @as("round") Round
  | @as("square") Square

@unboxed
type cursor =
  | @as("auto") Auto
  | @as("default") Default
  | @as("none") None
  | @as("context-menu") ContextMenu
  | @as("help") Help
  | @as("pointer") Pointer
  | @as("progress") Progress
  | @as("wait") Wait
  | @as("cell") Cell
  | @as("crosshair") Crosshair
  | @as("text") Text
  | @as("vertical-text") VerticalText
  | @as("alias") Alias
  | @as("copy") Copy
  | @as("move") Move
  | @as("no-drop") NoDrop
  | @as("not-allowed") NotAllowed
  | @as("grab") Grab
  | @as("grabbing") Grabbing
  | @as("all-scroll") AllScroll
  | @as("col-resize") ColResize
  | @as("row-resize") RowResize
  | @as("n-resize") NResize
  | @as("e-resize") EResize
  | @as("s-resize") SResize
  | @as("w-resize") WResize
  | @as("ne-resize") NeResize
  | @as("nw-resize") NwResize
  | @as("se-resize") SeResize
  | @as("sw-resize") SwResize
  | @as("ew-resize") EwResize
  | @as("ns-resize") NsResize
  | @as("nesw-resize") NeswResize
  | @as("nwse-resize") NwseResize
  | @as("zoom-int") ZoomIn
  | @as("zoom-out") ZoomOut
