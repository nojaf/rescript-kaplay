open Kaplay

@val @scope("screen")
external screenWidth: int = "width"

@val @scope("screen")
external screenHeight: int = "height"

@scope("Math")
external min: (int, int) => int = "min"

let k = kaplay(
  ~initOptions={
    // width: min(720, screenWidth),
    // height: min(360, screenHeight),
    global: false,
    background: "#6495ED",
    scale: 1.,
  },
)
