open Kaplay

@scope("window")
external innerWidth: float = "innerWidth"

@scope("window")
external innerHeight: float = "innerHeight"

let gameWidth = 300.
let gameHeight = 400.

let scale = min(
  // Don't scale larger than 1.5
  1.5,
  // Scale via width or height
  min(innerWidth / gameWidth, innerHeight / gameHeight),
)

let k = Context.kaplay(
  ~initOptions={
    background: "#e5e7eb",
    global: false,
    scale,
    crisp: true,
    width: Float.toInt(gameWidth),
    height: Float.toInt(gameHeight),
  },
)

// k.debug.inspect = true
