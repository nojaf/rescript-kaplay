type t = {
  tex: Texture.t,
  frams: array<Types.quad>,
}

@send
external width: t => float = "width"

@send
external height: t => float = "height"
