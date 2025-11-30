open Kaplay

type ruleSystemState = {
  self: Pokemon.t,
  opponent: Pokemon.t,
  lastAttackAt: float,
}

module Facts = {
  open RuleSystem
  let playerCentered = Fact("playerCentered")
  let playerBelow = Fact("playerBelow")
}

let isPlayerCentered = (rs: RuleSystem.t<ruleSystemState>): bool => {
  let distance =
    Stdlib_Math.abs(
      rs.state.self->Pokemon.getPosX - rs.state.opponent->Pokemon.getPosX,
    )->Stdlib_Math.round
  distance == 0.
}

let isPlayerBelow = (rs: RuleSystem.t<ruleSystemState>): bool => {
  rs.state.self->Pokemon.getPosY < rs.state.opponent->Pokemon.getPosY
}

let negate = (predicate: RuleSystem.predicate<ruleSystemState>): RuleSystem.predicate<
  ruleSystemState,
> => {
  rs => !predicate(rs)
}

let make = (k: Context.t, ~pokemonId: int, ~level: int, player: Pokemon.t): Pokemon.t => {
  let enemy: Pokemon.t = Pokemon.make(k, ~pokemonId, ~level, Opponent)

  let rs = RuleSystem.make(k)
  rs.state = {
    self: enemy,
    opponent: player,
    lastAttackAt: 0.,
  }

  rs->RuleSystem.addRuleAssertingFact(isPlayerCentered, Facts.playerCentered, ~grade=Grade(1.))
  rs->RuleSystem.addRuleRetractingFact(
    negate(isPlayerCentered),
    Facts.playerCentered,
    ~grade=Grade(1.),
  )

  rs->RuleSystem.addRuleAssertingFact(isPlayerBelow, Facts.playerBelow, ~grade=Grade(1.))
  rs->RuleSystem.addRuleRetractingFact(negate(isPlayerBelow), Facts.playerBelow, ~grade=Grade(1.))

  enemy->Pokemon.onUpdate(() => {
    rs->RuleSystem.reset
    rs->RuleSystem.execute

    // check for facts...
    switch RuleSystem.gradeForFact(rs, Facts.playerCentered) {
    | Grade(g) if g < 1.0 => {
        let deltaX = Stdlib_Math.round(player->Pokemon.getPosX - enemy->Pokemon.getPosX)
        if deltaX != 0. {
          let x = deltaX > 0. ? 120. : -120.
          enemy->Pokemon.move(k->Context.vec2World(x, 0.))
        }
      }
    | Grade(g) if g == 1.0 => () // Ember.cast(enemy)
    | _ => ()
    }
  })

  k->Context.onKeyPress(key => {
    switch key {
    | Space => Console.table(rs.facts->Map.entries->Iterator.toArray)
    | _ => ()
    }
  })

  enemy
}
