open Kaplay

type ruleSystemState = {
  self: Pokemon.t,
  opponent: Pokemon.t,
  mutable opponentAttacks: array<Types.rect<Vec2.World.t>>,
  lastAttackAt: float,
}

module Facts = {
  open RuleSystem
  let playerCentered = Fact("playerCentered")
  let playerBelow = Fact("playerBelow")

  /**
   The is a game object with tag attack in front of the enemy.
   */
  let attackIncoming = Fact("attackIncoming")
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

let isAttackIncoming = (rs: RuleSystem.t<ruleSystemState>): bool => {
  let selfX = rs.state.self->Pokemon.getPosX
  let halfWidth = rs.state.self->Pokemon.getWidth / 2.
  let safetyMargin = Stdlib_Math.random() * 10.
  let selfStartX = selfX - halfWidth - safetyMargin
  let selfEndX = selfX + halfWidth + safetyMargin

  rs.state.opponentAttacks->Array.some(attack => {
    let attackStartX = attack.pos.x
    let attackEndX = attack.pos.x + attack.width
    // Simple overlap check: two ranges overlap if there's no gap between them!
    // They overlap if: enemy doesn't start after attack ends AND attack doesn't start after enemy ends.
    // This covers all cases: partial overlaps (left/right), complete containment, and edge touches.
    selfStartX <= attackEndX && attackStartX <= selfEndX
  })
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
    opponentAttacks: [],
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

  rs->RuleSystem.addRuleAssertingFact(isAttackIncoming, Facts.attackIncoming, ~grade=Grade(1.))
  rs->RuleSystem.addRuleRetractingFact(
    negate(isAttackIncoming),
    Facts.attackIncoming,
    ~grade=Grade(1.),
  )

  enemy->Pokemon.onUpdate(() => {
    rs->RuleSystem.reset

    let playerAttacks =
      k
      ->Context.query({
        include_: [Attack.tag, Team.player],
        hierarchy: Descendants,
      })
      ->Array.map((attack: Attack.customType<_>) => attack.getWorldRect())
    rs.state.opponentAttacks = playerAttacks

    rs->RuleSystem.execute

    let (attackOnTheLeft, attackOnTheRight) = {
      let attackOnTheLeft = ref(false)
      let attackOnTheRight = ref(false)
      playerAttacks->Array.forEach(attack => {
        if attack.pos.x < enemy->Pokemon.getPosX {
          attackOnTheLeft.contents = true
        } else if attack.pos.x > enemy->Pokemon.getPosX {
          attackOnTheRight.contents = true
        }
      })
      (attackOnTheLeft.contents, attackOnTheRight.contents)
    }

    // check for facts...
    switch (
      RuleSystem.gradeForFact(rs, Facts.attackIncoming),
      RuleSystem.gradeForFact(rs, Facts.playerCentered),
    ) {
    | (Grade(attackInComingGrade), _) if attackInComingGrade > 0.0 => {
        // Move away from the attack
        if attackOnTheLeft {
          enemy->Pokemon.move(k->Context.vec2World(40., 0.))
        } else if attackOnTheRight {
          enemy->Pokemon.move(k->Context.vec2World(-40., 0.))
        }
      }
    | (_, Grade(g)) if g < 1.0 => {
      // Move in front of the player
        let deltaX = Stdlib_Math.round(player->Pokemon.getPosX - enemy->Pokemon.getPosX)
        if deltaX > 0. && !attackOnTheRight {
          enemy->Pokemon.move(k->Context.vec2World(120., 0.))
        } else if deltaX < 0. && !attackOnTheLeft {
          enemy->Pokemon.move(k->Context.vec2World(-120., 0.))
        }
      }
    | (_, Grade(g)) if g == 1.0 && enemy.attackStatus == CanAttack => 
      // Attack the player
      Ember.cast(enemy)
    | _ => ()
    }
  })

  // k->Context.onKeyPress(key => {
  //   switch key {
  //   | Space => Console.table(rs.facts->Map.entries->Iterator.toArray)
  //   | _ => ()
  //   }
  // })

  enemy
}
