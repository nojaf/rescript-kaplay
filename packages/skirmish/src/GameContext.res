open Kaplay

@scope("window")
external innerWidth: float = "innerWidth"

@scope("window")
external innerHeight: float = "innerHeight"

let scale = min(
  // Don't scale larger than 1.5
  1.5,
  // Scale via width or height
  min(innerWidth / 800., innerHeight / 400.),
)


let k = Context.kaplay(
  ~initOptions={
    background: "#e5e7eb",
    global: false,
    scale,
    crisp: true,
    width: 300,
    height: 400,
  },
)