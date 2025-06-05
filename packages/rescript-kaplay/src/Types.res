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
