open Kaplay

type ruleSystemState = {
  enemy: Pokemon.t,
  player: Pokemon.t,
  mutable playerAttacks: array<Types.rect<Vec2.World.t>>,
  lastAttackAt: float,
}

module Facts = {
  open RuleSystem
  let playerCentered = Fact("playerCentered")
  let playerBelow = Fact("playerBelow")

  let attackInFrontOfEnemy = Fact("attackInFrontOfEnemy")
  let attackOnTheLeftOfEnemy = Fact("attackOnTheLeftOfEnemy")
  let attackOnTheRightOfEnemy = Fact("attackOnTheRightOfEnemy")

  // let attackIncoming = Fact("attackIncoming")
}

let isPlayerCentered = (rs: RuleSystem.t<ruleSystemState>): bool => {
  let distance =
    Stdlib_Math.abs(
      rs.state.enemy->Pokemon.getPosX - rs.state.player->Pokemon.getPosX,
    )->Stdlib_Math.round
  distance == 0.
}

let isPlayerBelow = (rs: RuleSystem.t<ruleSystemState>): bool => {
  rs.state.enemy->Pokemon.getPosY < rs.state.player->Pokemon.getPosY
}

// let isAttackIncoming = (rs: RuleSystem.t<ruleSystemState>): bool => {
//   let selfX = rs.state.enemy->Pokemon.getPosX
//   let halfWidth = rs.state.enemy->Pokemon.getWidth / 2.
//   let safetyMargin = Stdlib_Math.random() * 10.
//   let selfStartX = selfX - halfWidth - safetyMargin
//   let selfEndX = selfX + halfWidth + safetyMargin

//   rs.state.playerAttacks->Array.some(attack => {
//     let attackStartX = attack.pos.x
//     let attackEndX = attack.pos.x + attack.width
//     // Simple overlap check: two ranges overlap if there's no gap between them!
//     // They overlap if: enemy doesn't start after attack ends AND attack doesn't start after enemy ends.
//     // This covers all cases: partial overlaps (left/right), complete containment, and edge touches.
//     selfStartX <= attackEndX && attackStartX <= selfEndX
//   })
// }

let negate = (predicate: RuleSystem.predicate<ruleSystemState>): RuleSystem.predicate<
  ruleSystemState,
> => {
  rs => !predicate(rs)
}

let makeRuleSystem = (k: Context.t, ~enemy: Pokemon.t, ~player: Pokemon.t): RuleSystem.t<
  ruleSystemState,
> => {
  let rs = RuleSystem.make(k)
  rs.state = {
    enemy,
    player,
    playerAttacks: [],
    lastAttackAt: 0.,
  }

  // rs->RuleSystem.addRuleAssertingFact(isPlayerCentered, Facts.playerCentered, ~grade=Grade(1.))
  // rs->RuleSystem.addRuleRetractingFact(
  //   negate(isPlayerCentered),
  //   Facts.playerCentered,
  //   ~grade=Grade(1.),
  // )

  // rs->RuleSystem.addRuleAssertingFact(isPlayerBelow, Facts.playerBelow, ~grade=Grade(1.))
  // rs->RuleSystem.addRuleRetractingFact(negate(isPlayerBelow), Facts.playerBelow, ~grade=Grade(1.))

  // TODO: add test to assert grades are correct
  // And consider a debug tool to view the grades in realtime during debug.

  // Check for attacks on the left
  // TODO: we would have a better assement of the dange of the attack on the left
  // by taking the speed of the attack and the speed of the enemy into account.
  rs->RuleSystem.addRuleExecutingAction(
    rs => rs.state.playerAttacks->Array.length > 0,
    rs => {
      let grade = ref(RuleSystem.Grade(0.))
      rs.state.playerAttacks->Array.forEach(attack => {
        // Check if attack is on the left
        if attack.pos.x + attack.width < rs.state.enemy->Pokemon.getPosX {
          // is the attack in front of the enemy?
          let attackCoord: Vec2.World.t = {
            if attack.pos.y + attack.height >= rs.state.enemy->Pokemon.getPosY {
              // We care about the right upper corner of the attack
              k->Context.vec2World(attack.pos.x + attack.width, attack.pos.y)
            } else {
              // We care about the right lower corner of the attack
              k->Context.vec2World(attack.pos.x + attack.width, attack.pos.y + attack.height)
            }
          }

          // calculate grade based on the distance between the attack and the enemy
          let squaredDistance = attackCoord->Vec2.World.sdist(rs.state.enemy->Pokemon.worldPos)
          // We multiply the enemy width by 3 to make it more sensitive to the attack.
          let enemyWidth = Stdlib_Math.pow(3. * rs.state.enemy->Pokemon.getWidth, ~exp=2.)
          let currentGrade =
            squaredDistance == 0.
              ? RuleSystem.Grade(1.)
              : RuleSystem.Grade(enemyWidth / squaredDistance)

          // replace current grade is higher
          if grade.contents < currentGrade {
            grade.contents = currentGrade
          }
        }
      })

      if grade.contents > RuleSystem.Grade(0.) {
        rs->RuleSystem.assertFact(Facts.attackOnTheLeftOfEnemy, ~grade=grade.contents)
      }
    },
    ~salient=Salience(0.),
  )

  // rs->RuleSystem.addRuleAssertingFact(isAttackIncoming, Facts.attackIncoming, ~grade=Grade(1.))
  // rs->RuleSystem.addRuleRetractingFact(
  //   negate(isAttackIncoming),
  //   Facts.attackIncoming,
  //   ~grade=Grade(1.),
  // )

  rs
}

let getPlayerAttacks = (k: Context.t): array<Types.rect<Vec2.World.t>> => {
  k
  ->Context.query({
    include_: [Attack.tag, Team.player],
    hierarchy: Descendants,
  })
  ->Array.map((attack: Attack.customType<_>) => attack.getWorldRect())
}

let forOf: (array<'t>, 't => unit, unit => bool) => unit = %raw(`
function (items, callback, shouldBreak) {
  for (let i = 0; i < items.length; i++) {
    if (shouldBreak()) {
      break;
    }
    callback(items[i])
  }
}
`)

/**
 Verifies the attacks coming from the player.
 First boolean is an attack on the left of the enemy.
 Second boolean is an attack on the right of the enemy.
 */
let verifyAttacks = (rs: RuleSystem.t<ruleSystemState>): (bool, bool) => {
  let attackOnTheLeft = ref(false)
  let attackOnTheRight = ref(false)
  let enemyX = rs.state.enemy->Pokemon.getPosX
  // We use a while loop to be able to have an early exit if we find an attack on the left and right.
  // In that case, we don't need to iterate over all the attacks.
  forOf(
    rs.state.playerAttacks,
    attack => {
      let attackX = attack.pos.x
      if attackX < enemyX {
        attackOnTheLeft.contents = true
      } else if attackX > enemyX {
        attackOnTheRight.contents = true
      }
    },
    () => attackOnTheLeft.contents && attackOnTheRight.contents,
  )

  (attackOnTheLeft.contents, attackOnTheRight.contents)
}

let update = (k: Context.t, rs: RuleSystem.t<ruleSystemState>, ()) => {
  rs->RuleSystem.reset
  rs.state.playerAttacks = getPlayerAttacks(k)
  rs->RuleSystem.execute

  // let (attackOnTheLeft, attackOnTheRight) = verifyAttacks(rs)

  // check for facts...
  // switch (
  //   RuleSystem.gradeForFact(rs, Facts.attackOnTheLeftOfEnemy),
  //   RuleSystem.gradeForFact(rs, Facts.playerCentered),
  // ) {
  // | (Grade(attackInComingGrade), _) if attackInComingGrade > 0.0 => {
  //     // Move away from the attack
  //     if attackOnTheLeft {
  //       // Move to the right of the attack
  //       rs.state.enemy->Pokemon.move(k->Context.vec2World(40., 0.))
  //     } else if attackOnTheRight {
  //       // Move to the left of the attack
  //       rs.state.enemy->Pokemon.move(k->Context.vec2World(-40., 0.))
  //     } else {
  //       // The attack is right in front of us.
  //       // We need to dodge it in either direction.
  //       // We pick the direction where there is most space.
  //       let distanceLeft = rs.state.enemy->Pokemon.getPosX
  //       let distanceRight = k->Context.width - rs.state.enemy->Pokemon.getPosX
  //       if distanceLeft > distanceRight {
  //         rs.state.enemy->Pokemon.move(k->Context.vec2World(-40., 0.))
  //       } else {
  //         rs.state.enemy->Pokemon.move(k->Context.vec2World(40., 0.))
  //       }
  //     }
  //   }
  // | (_, Grade(g)) if g < 1.0 => {
  //     // Move in front of the player
  //     let deltaX = Stdlib_Math.round(
  //       rs.state.player->Pokemon.getPosX - rs.state.enemy->Pokemon.getPosX,
  //     )
  //     if deltaX > 0. && !attackOnTheRight {
  //       rs.state.enemy->Pokemon.move(k->Context.vec2World(120., 0.))
  //     } else if deltaX < 0. && !attackOnTheLeft {
  //       rs.state.enemy->Pokemon.move(k->Context.vec2World(-120., 0.))
  //     }
  //   }
  // | (_, Grade(g)) if g == 1.0 && rs.state.enemy.attackStatus == CanAttack =>
  //   // Attack the player
  //   Ember.cast(rs.state.enemy)
  // | _ => ()
  // }
}

let make = (k: Context.t, ~pokemonId: int, ~level: int, player: Pokemon.t): Pokemon.t => {
  let enemy: Pokemon.t = Pokemon.make(k, ~pokemonId, ~level, Opponent)
  let rs = makeRuleSystem(k, ~enemy, ~player)

  enemy->Pokemon.onUpdate(update(k, rs, ...))

  DebugRuleSystem.make(k, rs)

  // k->Context.onKeyPress(key => {
  //   switch key {
  //   | Space => Console.table(rs.facts->Map.entries->Iterator.toArray)
  //   | _ => ()
  //   }
  // })

  enemy
}
