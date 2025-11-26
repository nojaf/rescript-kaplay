type t = {
  mutable x: float,
  mutable y: float,
}

/**
`Vec2.x(vec2)` get the x coordinate of the vector
This is the same as `vec2.x` but more convenient to use when piping.
 */
@get
external x: t => float = "x"

/**
`Vec2.y(vec2)` get the y coordinate of the vector
This is the same as `vec2.y` but more convenient to use when piping.
 */
@get
external y: t => float = "y"

@send
external add: (t, t) => t = "add"

@send
external sub: (t, t) => t = "sub"

@send
external scale: (t, t) => t = "scale"

@send
external scaleWith: (t, float) => t = "scale"

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
