module Impl = (
  T: {
    type t
  },
) => {
  /**
`x(vec2)` get the x coordinate of the vector
This is the same as `vec2.x` but more convenient to use when piping.

## Examples

```rescript
external vec : Vec2.World.t = "someWorldVector"
let x = vec->Vec2.World.x
// x is 10.
```
 */
  @get
  external x: T.t => float = "x"

  /**
`y(vec2)` get the y coordinate of the vector
This is the same as `vec2.y` but more convenient to use when piping.
 */
  @get
  external y: T.t => float = "y"

  /**
  `add(vec2, vec2)` adds two vectors together by summing their x and y components.

   ## Examples
   ```rescript
   let vec1 = k->Context.vec2(10., 20.)
   let vec2 = k->Context.vec2(30., 40.)
   let vec3 = vec1->Vec2.add(vec2)
   // vec3 is {x: 40., y: 60.}
   ```
   */
  @send
  external add: (T.t, T.t) => T.t = "add"

  @send
  external addWithXY: (T.t, float, float) => T.t = "add"

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

  /** Get squared distance between another vector */
  @send
  external sdist: (T.t, T.t) => float = "sdist"

  @send
  external dot: (T.t, T.t) => float = "dot"

  @send
  external clone: T.t => T.t = "clone"
}

/**
 Absolute coordinate system based on the root object.
 */
module World = {
  type t = {
    mutable x: float,
    mutable y: float,
  }

  include Impl({type t = t})
}

/**
 Camera-relative coordinate system based on the camera position.
 */
module Screen = {
  type t = {
    mutable x: float,
    mutable y: float,
  }

  include Impl({type t = t})
}

/**
 Relative coordinate system based on the parent object.
 */
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
 Use in tile-based coordinate systems.
 Like in `level` components.
 */
module Tile = {
  type t = {mutable x: float, mutable y: float}

  include Impl({type t = t})
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
