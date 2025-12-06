open Kaplay

type ruleSystemState = {
  enemy: Pokemon.t,
  player: Pokemon.t,
  mutable playerAttacks: array<Attack.Unit.t>,
  lastAttackAt: float,
}

module Facts = {
  open RuleSystem
  let playerCentered = Fact("playerCentered")
  let playerBelow = Fact("playerBelow")

  let attackInCenterOfEnemy = Fact("attackInCenterOfEnemy")
  let attackOnTheLeftOfEnemy = Fact("attackOnTheLeftOfEnemy")
  let attackOnTheRightOfEnemy = Fact("attackOnTheRightOfEnemy")

  // let attackIncoming = Fact("attackIncoming")
}

module Salience = {
  open RuleSystem
  let baseFacts = Salience(0.0)
  let derivedFacts = Salience(10.0)
  let decisions = Salience(20.0)
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

let overlapX = ((ax1, ax2), (bx1, bx2)) => {
  Stdlib_Math.max(ax1, bx1) <= Stdlib_Math.min(ax2, bx2)
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
      // Track maximum grades for each fact type
      let leftGrade = ref(RuleSystem.Grade(0.))
      let rightGrade = ref(RuleSystem.Grade(0.))
      let centerGrade = ref(RuleSystem.Grade(0.))

      let enemyWorldPos = rs.state.enemy->Pokemon.worldPos
      let enemyStartX = enemyWorldPos.x - rs.state.enemy.halfSize
      let enemyEndX = enemyWorldPos.x + rs.state.enemy.halfSize

      rs.state.playerAttacks->Array.forEach(attack => {
        let attackWorldRect = attack->Attack.Unit.getWorldRect
        let closestCorner = attack->Attack.Unit.getClosestCorner(k, ~pokemonPosition=enemyWorldPos)

        // Check is attack is in center of enemy
        if (
          overlapX(
            (enemyStartX, enemyEndX),
            (attackWorldRect.pos.x, attackWorldRect.pos.x + attackWorldRect.width),
          )
        ) {
          let squaredDistance = Vec2.World.sdist(
            enemyWorldPos,
            attackWorldRect->Kaplay.Math.Rect.centerWorld,
          )
          let currentGrade =
            squaredDistance == 0.
              ? RuleSystem.Grade(1.)
              : RuleSystem.Grade(rs.state.enemy.squaredPersonalSpace / squaredDistance)

          // replace current grade is higher
          if centerGrade.contents < currentGrade {
            centerGrade.contents = currentGrade
          }
        } // Check if attack is on the left
        else if closestCorner.x < enemyStartX {
          // calculate grade based on the distance between the attack and the enemy
          let squaredDistance = closestCorner->Vec2.World.sdist(enemyWorldPos)

          let currentGrade =
            squaredDistance == 0.
              ? RuleSystem.Grade(1.)
              : RuleSystem.Grade(rs.state.enemy.squaredPersonalSpace / squaredDistance)

          // replace current grade is higher
          if leftGrade.contents < currentGrade {
            leftGrade.contents = currentGrade
          }
        } else if closestCorner.x > enemyEndX {
          // calculate grade based on the distance between the attack and the enemy
          let squaredDistance = closestCorner->Vec2.World.sdist(enemyWorldPos)

          let currentGrade =
            squaredDistance == 0.
              ? RuleSystem.Grade(1.)
              : RuleSystem.Grade(rs.state.enemy.squaredPersonalSpace / squaredDistance)

          // replace current grade is higher
          if rightGrade.contents < currentGrade {
            rightGrade.contents = currentGrade
          }
        }
      })

      if leftGrade.contents > RuleSystem.Grade(0.) {
        rs->RuleSystem.assertFact(Facts.attackOnTheLeftOfEnemy, ~grade=leftGrade.contents)
      }
      if rightGrade.contents > RuleSystem.Grade(0.) {
        rs->RuleSystem.assertFact(Facts.attackOnTheRightOfEnemy, ~grade=rightGrade.contents)
      }
      if centerGrade.contents > RuleSystem.Grade(0.) {
        rs->RuleSystem.assertFact(Facts.attackInCenterOfEnemy, ~grade=centerGrade.contents)
      }
    },
    ~salient=Salience.baseFacts,
  )

  rs
}

let getPlayerAttacks = (k: Context.t): array<Attack.Unit.t> => {
  k
  ->Context.query({
    include_: [Attack.tag, Team.player],
    hierarchy: Descendants,
  })
  ->Array.filterMap(Attack.Unit.fromGameObj)
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
let // let verifyAttacks = (rs: RuleSystem.t<ruleSystemState>): (bool, bool) => {
//   let attackOnTheLeft = ref(false)
//   let attackOnTheRight = ref(false)
//   let enemyX = rs.state.enemy->Pokemon.getPosX
//   // We use a while loop to be able to have an early exit if we find an attack on the left and right.
//   // In that case, we don't need to iterate over all the attacks.
//   forOf(
//     rs.state.playerAttacks,
//     attack => {
//       let attackX = attack.pos.x
//       if attackX < enemyX {
//         attackOnTheLeft.contents = true
//       } else if attackX > enemyX {
//         attackOnTheRight.contents = true
//       }
//     },
//     () => attackOnTheLeft.contents && attackOnTheRight.contents,
//   )

//   (attackOnTheLeft.contents, attackOnTheRight.contents)
// }

update = (k: Context.t, rs: RuleSystem.t<ruleSystemState>, ()) => {
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
