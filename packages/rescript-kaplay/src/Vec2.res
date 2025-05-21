type t = {
  mutable x: float,
  mutable y: float,
}

@send
external add: (t, t) => t = "add"

@send
external sub: (t, t) => t = "sub"

@send
external scale: (t, t) => t = "scale"

@send
external len: t => float = "len"

@send
external unit: t => t = "unit"

@send
external lerp: (t, t, float) => t = "lerp"

@send
external dist: (t, t) => float = "dist"

@send
external dot: (t, t) => float = "dot"
