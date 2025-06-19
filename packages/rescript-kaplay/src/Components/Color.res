type t = Types.color

@send @scope("Color")
external fromHex: (Context.t, string) => t = "fromHex"

let fromRGB: (Context.t, int, int, int) => t = %raw(`
function (k, r, g, b) {
    return new k.Color(r,g,b);
}
`)

@send
external darken: (t, float) => t = "darken"

@send
external lighten: (t, float) => t = "lighten"

@send
external invert: t => t = "invert"

@send
external mult: (t, t) => t = "mult"

@send
external lerp: (t, t, float) => t = "lerp"

@send
external toHSL: t => (float, float, float) = "toHSL"

@send
external eq: (t, t) => bool = "eq"

@send
external toHex: t => string = "toHex"

@send
external toArray: t => array<int> = "toArray"

/* Constants */
@get
external red: Context.t => t = "RED"
@get
external green: Context.t => t = "GREEN"
@get
external blue: Context.t => t = "BLUE"
@get
external yellow: Context.t => t = "YELLOW"
@get
external magenta: Context.t => t = "MAGENTA"
@get
external cyan: Context.t => t = "CYAN"
@get
external white: Context.t => t = "WHITE"
@get
external black: Context.t => t = "BLACK"

module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getColor: T.t => t = "color"

  @set
  external setColor: (T.t, Types.color) => unit = "color"

  /** Add a color from a color type */
  @send
  external addColor: (Context.t, t) => Types.comp = "color"

  /** Add a color from a hex string or css color name */
  @send
  external addColorFromHex: (Context.t, string) => Types.comp = "color"

  /** Add a color from rgb value */
  @send
  external addColorFromRgb: (Context.t, int, int, int) => Types.comp = "color"
}
