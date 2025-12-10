type t = {
  tex: Texture.t,
  frams: array<Types.quad>,
}

@get
external width: t => float = "width"

@get
external height: t => float = "height"
