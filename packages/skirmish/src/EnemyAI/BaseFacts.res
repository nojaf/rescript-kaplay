/** Base facts module for enemy AI.
  *
  * This module computes base facts directly from game state (no dependencies on other facts).
  * It provides foundational information about attack positions, space availability, and
  * player position relative to the enemy. These facts are used by DerivedFacts and
  * DefensiveFacts modules to make higher-level decisions.
  */
open Kaplay

let salience = RuleSystem.Salience(0.0)

let overlapX = ((ax1, ax2), (bx1, bx2)) => {
  Stdlib_Math.max(ax1, bx1) <= Stdlib_Math.min(ax2, bx2)
}

let addRules = (k: Context.t, rs: RuleSystem.t<RuleSystemState.t>) => {
  // Base fact: Attack positions
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
        rs->RuleSystem.assertFact(AIFacts.attackOnTheLeftOfEnemy, ~grade=leftGrade.contents)
      }
      if rightGrade.contents > RuleSystem.Grade(0.) {
        rs->RuleSystem.assertFact(AIFacts.attackOnTheRightOfEnemy, ~grade=rightGrade.contents)
      }
      if centerGrade.contents > RuleSystem.Grade(0.) {
        rs->RuleSystem.assertFact(AIFacts.attackInCenterOfEnemy, ~grade=centerGrade.contents)
      }
    },
    ~salience,
  )

  // Base fact: Space availability
  rs->RuleSystem.addRuleExecutingAction(
    _rs => true,
    rs => {
      let enemyWorldPos = rs.state.enemy->Pokemon.worldPos
      let enemyStartX = enemyWorldPos.x - rs.state.enemy.halfSize
      let enemyEndX = enemyWorldPos.x + rs.state.enemy.halfSize
      let leftSpace = enemyStartX / k->Context.width
      let rightSpace = (k->Context.width - enemyEndX) / k->Context.width
      if leftSpace > 0. {
        rs->RuleSystem.assertFact(AIFacts.hasSpaceOnTheLeft, ~grade=RuleSystem.Grade(leftSpace))
      }
      if rightSpace > 0. {
        rs->RuleSystem.assertFact(AIFacts.hasSpaceOnTheRight, ~grade=RuleSystem.Grade(rightSpace))
      }
    },
    ~salience,
  )

  // Base fact: Player position relative to enemy
  rs->RuleSystem.addRuleExecutingAction(
    _rs => true,
    rs => {
      let enemyWorldPos = rs.state.enemy->Pokemon.worldPos
      let playerWorldPos = rs.state.player->Pokemon.worldPos
      let horizontalDistance = playerWorldPos.x - enemyWorldPos.x

      // Use small threshold to prevent oscillation when very close to aligned
      if Stdlib_Math.abs(horizontalDistance) < 1.0 {
        // Within 1 pixel - considered aligned, don't assert left/right facts
        ()
      } else if horizontalDistance < 0.0 {
        // Player is to the left
        rs->RuleSystem.assertFact(AIFacts.isPlayerLeft, ~grade=RuleSystem.Grade(1.0))
      } else {
        // Player is to the right
        rs->RuleSystem.assertFact(AIFacts.isPlayerRight, ~grade=RuleSystem.Grade(1.0))
      }
    },
    ~salience,
  )
}
