module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getHp: T.t => int = "hp"

  @set
  external setHp: (T.t, int) => unit = "hp"

  @get
  external getMaxHp: T.t => int = "maxHP"

  @set
  external setMaxHp: (T.t, int) => unit = "maxHP"

  @get
  external getDead: T.t => bool = "dead"

  /**
 `onHurt(t, deltaHP => unit)` register an event that runs when the hp is lowered.
 */
  @send
  external onHurt: (T.t, int => unit) => unit = "onHurt"

  /**
 `hurt(t, deltaHP => unit)` register an event that runs when the hp is lowered.
 */
  @send
  external onHurtWithController: (T.t, int => unit) => KEventController.t = "onHurt"

  /**
 `onHeal(t, deltaHP => unit)` register an event that runs when the hp is increased.
 */
  @send
  external onHeal: (T.t, int => unit) => unit = "onHeal"

  /**
 `onHeal(t, deltaHP => unit)` register an event that runs when the hp is increased.
 */
  @send
  external onHealWithController: (T.t, int => unit) => KEventController.t = "onHeal"

  /**
 `onDeath(t, unit => unit)` register an event that runs when the hp becomes zero.
 */
  @send
  external onDeath: (T.t, unit => unit) => unit = "onDeath"

  /**
 `onDeath(t, unit => unit)` register an event that runs when the hp becomes zero.
 */
  @send
  external onDeathWithController: (T.t, unit => unit) => KEventController.t = "onDeath"

  /**
 `addHealth(context, hp, ~maxHp=?)` handles health related logic and events.
 */
  @send
  external addHealth: (Context.t, int, ~maxHP: int=?) => Types.comp = "health"
}
