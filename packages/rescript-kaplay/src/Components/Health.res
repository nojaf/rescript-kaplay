module Comp = (
  T: {
    type t
  },
) => {
  @send
  external hurt: (T.t, int) => unit = "hurt"

  @send
  external heal: (T.t, int) => unit = "heal"

  @send
  external hp: T.t => int = "hp"

  @send
  external setHP: (T.t, int) => unit = "setHP"

  @send
  external onHurt: (T.t, int => unit) => KEventController.t = "onHurt"

  @send
  external onHeal: (T.t, (~amount: int=?) => unit) => KEventController.t = "onHeal"

  @send
  external onDeath: (T.t, unit => unit) => KEventController.t = "onDeath"

  @send
  external addHealth: (Context.t, int, ~maxHp: int=?) => Types.comp = "health"
}
