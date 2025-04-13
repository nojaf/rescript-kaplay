open Kaplay

@val @scope("screen")
external screenWidth: int = "width"

@val @scope("screen")
external screenHeight: int = "height"

let k = kaplay(
  ~initOptions={
    width: 720, // screenWidth,
    height: 320, // screenHeight,
    global: false,
    background: "#6495ED",
    scale: 1.,
    letterbox: true,
  },
)
