type t = {mutable paused: bool}

/**
 Start playing audio. Use `audio.paused = true` to pause it.
 */
@send
external play: (t, ~time: float=?) => unit = "play"

/**
 Stop playing audio. Will start playing from the beginning when `play` is called again.
 */
@send
external stop: t => unit = "stop"
