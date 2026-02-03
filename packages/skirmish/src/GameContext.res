open Kaplay

@scope("window")
external innerWidth: float = "innerWidth"

@scope("window")
external innerHeight: float = "innerHeight"

let gameWidth = 360.
let gameHeight = 649.

let k = Context.kaplay(
  ~initOptions={
    background: "#e5e7eb",
    global: false,
    crisp: true,
    width: Float.toInt(gameWidth),
    height: Float.toInt(gameHeight),
  },
)

// k.debug.inspect = true
