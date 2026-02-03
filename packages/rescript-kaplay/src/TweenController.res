type t = {mutable paused: bool}

@send
external cancel: t => unit = "cancel"

@send
external onEnd: (t, unit => unit) => unit = "onEnd"

@send
external then: (t, unit => unit) => t = "then"

@send
external finish: t => unit = "finish"

let empty = %raw(`{
    timeLeft: 0,
    currentTime: 0,
    paused: false,
    cancel: function() {},
    onEnd: function() {},
    then: function(action) { return this; },
    finish: function() {},
}`)
