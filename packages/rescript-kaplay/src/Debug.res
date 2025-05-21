type t

@send
external log: (t, 't) => unit = "log"

@set
external setInspect: (t, bool) => unit = "inspect"
