module Impl = (
  T: {
    type t
  },
) => {
  /**
`Vec2.x(vec2)` get the x coordinate of the vector
This is the same as `vec2.x` but more convenient to use when piping.
 */
  @get
  external x: T.t => float = "x"

  /**
`Vec2.y(vec2)` get the y coordinate of the vector
This is the same as `vec2.y` but more convenient to use when piping.
 */
  @get
  external y: T.t => float = "y"

  @send
  external add: (T.t, T.t) => T.t = "add"

  @send
  external sub: (T.t, T.t) => T.t = "sub"

  @send
  external scale: (T.t, T.t) => T.t = "scale"

  @send
  external scaleWith: (T.t, float) => T.t = "scale"

  @send
  external len: T.t => float = "len"

  @send
  external unit: T.t => T.t = "unit"

  @send
  external lerp: (T.t, T.t, float) => T.t = "lerp"

  @send
  external dist: (T.t, T.t) => float = "dist"

  @send
  external dot: (T.t, T.t) => float = "dot"
}

module World = {
  type t = {
    mutable x: float,
    mutable y: float,
  }

  include Impl({type t = t})
}

module Screen = {
  type t = {
    mutable x: float,
    mutable y: float,
  }

  include Impl({type t = t})
}

module Local = {
  type t = {
    mutable x: float,
    mutable y: float,
  }

  include Impl({type t = t})

  /** Use with caution, this is useful in additions or scaling operations */
  external asWorld: t => World.t = "%identity"
}

/**
 * Unit/direction vectors - represent direction, not position.
 * These are normalized vectors that can be used in any coordinate space.
 * Examples: vec2Up, vec2Left, velocity directions, etc.
 */
module Unit = {
  type t = {
    mutable x: float,
    mutable y: float,
  }

  include Impl({type t = t})

  external asWorld: t => World.t = "%identity"
  external asLocal: t => Local.t = "%identity"
}

/**
 * Type alias for backward compatibility.
 * Defaults to LocalVec2.t - use specific types (LocalVec2.t, World.t, Screen.t) when possible.
 */
type t = Local.t

include Impl({type t = t})
