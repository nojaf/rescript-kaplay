open Kaplay

let screen = {
  "width": 720,
  "height": 280,
}

let k = kaplay(
  ~initOptions={
    width: screen["width"],
    height: screen["height"],
    global: false,
    background: "#6495ED",
    scale: 1.,
  },
)
