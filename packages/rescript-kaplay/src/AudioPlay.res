type t

@send
external play: (t, ~time: float=?) => unit = "play"
