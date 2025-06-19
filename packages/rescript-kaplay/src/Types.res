type comp

@unboxed
type key =
  | @as("f1") F1
  | @as("f2") F2
  | @as("f3") F3
  | @as("f4") F4
  | @as("f5") F5
  | @as("f6") F6
  | @as("f7") F7
  | @as("f8") F8
  | @as("f9") F9
  | @as("f10") F10
  | @as("f11") F11
  | @as("f12") F12
  | @as("`") Backtick
  | @as("1") One
  | @as("2") Two
  | @as("3") Three
  | @as("4") Four
  | @as("5") Five
  | @as("6") Six
  | @as("7") Seven
  | @as("8") Eight
  | @as("9") Nine
  | @as("0") Zero
  | @as("-") Minus
  | @as("+") Plus
  | @as("=") Equals
  | @as("q") Q
  | @as("w") W
  | @as("e") E
  | @as("r") R
  | @as("t") T
  | @as("y") Y
  | @as("u") U
  | @as("i") I
  | @as("o") O
  | @as("p") P
  | @as("[") LeftBracket
  | @as("]") RightBracket
  | @as("\\") BackwardSlash
  | @as("a") A
  | @as("s") S
  | @as("d") D
  | @as("f") F
  | @as("g") G
  | @as("h") H
  | @as("j") J
  | @as("k") K
  | @as("l") L
  | @as(";") Semicolon
  | @as("'") Quote
  | @as("z") Z
  | @as("x") X
  | @as("c") C
  | @as("v") V
  | @as("b") B
  | @as("n") N
  | @as("m") M
  | @as(",") Comma
  | @as(".") Period
  | @as("/") ForwardSlash
  | @as("escape") Escape
  | @as("backspace") Backspace
  | @as("enter") Enter
  | @as("tab") Tab
  | @as("control") Control
  | @as("alt") Alt
  | @as("meta") Meta
  | @as("space") Space
  | @as(" ") SingleSpace
  | @as("left") Left
  | @as("right") Right
  | @as("up") Up
  | @as("down") Down
  | @as("shift") Shift
  | @as("string") String(string)

type color =  {
  r: int,
  g: int,
  b: int,
}

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

type blendMode =
  | @as("normal") Normal
  | @as("add") Add
  | @as("multiply") Multiply
  | @as("screen") Screen
  | @as("overlay") Overlay

type outline = {
  mutable width?: float,
  mutable color?: color,
  mutable opacity?: float,
  mutable join?: lineJoin,
  mutable miterLimit?: float,
  mutable cap?: lineCap,
}

type textAlign =
  | @as("left") Left
  | @as("center") Center
  | @as("right") Right

type shape
type rect = {
  pos: Vec2.t,
  width: float,
  height: float,
}
type circle = {
  radius: float,
  center: Vec2.t
}
type polygon
