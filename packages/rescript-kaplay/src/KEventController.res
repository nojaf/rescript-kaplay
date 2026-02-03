type t

@send
external cancel: t => unit = "cancel"

let empty: t = %raw(`{ paused: false, cancel: () => {} }`)
