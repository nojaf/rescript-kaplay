open Kaplay

@unboxed
type dodgeDirection = | @as(true) Left | @as(false) Right

type ruleSystemState = {
  enemy: Pokemon.t,
  player: Pokemon.t,
  mutable playerAttacks: array<Attack.Unit.t>,
  mutable dodgeDirection: option<dodgeDirection>,
  lastAttackAt: float,
}

module Facts = {
  open RuleSystem

  let attackInCenterOfEnemy = Fact("attackInCenterOfEnemy")
  let attackOnTheLeftOfEnemy = Fact("attackOnTheLeftOfEnemy")
  let attackOnTheRightOfEnemy = Fact("attackOnTheRightOfEnemy")
  let hasSpaceOnTheLeft = Fact("hasSpaceOnTheLeft")
  let hasSpaceOnTheRight = Fact("hasSpaceOnTheRight")
}

module Salience = {
  open RuleSystem
  let baseFacts = Salience(0.0)
  // let derivedFacts = Salience(10.0)
  let decisions = Salience(20.0)
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
    dodgeDirection: None,
    lastAttackAt: 0.,
  }

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

  rs->RuleSystem.addRuleExecutingAction(
    _rs => true,
    _rs => {
      let enemyWorldPos = rs.state.enemy->Pokemon.worldPos
      let enemyStartX = enemyWorldPos.x - rs.state.enemy.halfSize
      let enemyEndX = enemyWorldPos.x + rs.state.enemy.halfSize
      let leftSpace = enemyStartX / k->Context.width
      let rightSpace = (k->Context.width - enemyEndX) / k->Context.width
      if leftSpace > 0. {
        rs->RuleSystem.assertFact(Facts.hasSpaceOnTheLeft, ~grade=RuleSystem.Grade(leftSpace))
      }
      if rightSpace > 0. {
        rs->RuleSystem.assertFact(Facts.hasSpaceOnTheRight, ~grade=RuleSystem.Grade(rightSpace))
      }
    },
    ~salient=Salience.baseFacts,
  )

  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      // Only dodge when there's an attack in the center (or center + sides)
      // Side attacks alone don't require dodging
      let RuleSystem.Grade(c) = RuleSystem.gradeForFact(rs, Facts.attackInCenterOfEnemy)
      c > 0.0
    },
    rs => {
      // Get all attack facts and space facts
      let RuleSystem.Grade(centerAttack) = RuleSystem.gradeForFact(rs, Facts.attackInCenterOfEnemy)
      let RuleSystem.Grade(leftAttack) = RuleSystem.gradeForFact(rs, Facts.attackOnTheLeftOfEnemy)
      let RuleSystem.Grade(rightAttack) = RuleSystem.gradeForFact(rs, Facts.attackOnTheRightOfEnemy)
      let RuleSystem.Grade(leftSpace) = RuleSystem.gradeForFact(rs, Facts.hasSpaceOnTheLeft)
      let RuleSystem.Grade(rightSpace) = RuleSystem.gradeForFact(rs, Facts.hasSpaceOnTheRight)

      // Calculate threat on each side
      // Left side threat = attacks on left + center (if center exists)
      // Right side threat = attacks on right + center (if center exists)
      let leftThreat = leftAttack + centerAttack
      let rightThreat = rightAttack + centerAttack

      // Determine preferred direction based on threats
      let (preferredDodgeDirection, shouldRecalculate) = if leftThreat > rightThreat {
        // More threat on left → move right
        (Right, true)
      } else if rightThreat > leftThreat {
        // More threat on right → move left
        (Left, true)
      } else {
        // Equal threats (only center attack)

        switch rs.state.dodgeDirection {
        | None => // No direction yet, pick based on space
          (leftSpace > rightSpace ? Left : Right, true)
        | Some(
            currentDirection,
          ) => // Already have a direction for equal threats, keep it to avoid oscillation
          (currentDirection, false)
        }
      }

      // Only recalculate final direction if we should (not when keeping existing direction)
      let finalDirection = if !shouldRecalculate {
        // Keep current direction (equal threats, already have direction)
        switch rs.state.dodgeDirection {
        | Some(dir) => dir
        | None => preferredDodgeDirection // Shouldn't happen, but fallback
        }
      } else {
        // Check if we have space in the preferred direction
        let hasSpaceInPreferred = switch preferredDodgeDirection {
        | Left => leftSpace > 0.0
        | Right => rightSpace > 0.0
        }

        // If no space in preferred direction, try the other side
        hasSpaceInPreferred
          ? preferredDodgeDirection
          : switch preferredDodgeDirection {
            | Left => rightSpace > 0.0 ? Right : Left
            | Right => leftSpace > 0.0 ? Left : Right
            }
      }

      switch rs.state.dodgeDirection {
      | None =>
        // Pick initial direction
        rs.state.dodgeDirection = Some(finalDirection)
      | Some(currentDirection) =>
        if currentDirection != finalDirection {
          rs.state.dodgeDirection = Some(finalDirection)
        }
      }
    },
    ~salient=Salience.decisions,
  )

  // Rule: Reset dodge direction when center attack is gone
  // We stop dodging once we've successfully dodged the center attack,
  // even if there are still attacks on the sides
  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      let RuleSystem.Grade(c) = RuleSystem.gradeForFact(rs, Facts.attackInCenterOfEnemy)
      c == 0.0
    },
    rs => {
      rs.state.dodgeDirection = None
    },
    ~salient=Salience.decisions,
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

let update = (k: Context.t, rs: RuleSystem.t<ruleSystemState>, ()) => {
  rs->RuleSystem.reset
  rs.state.playerAttacks = getPlayerAttacks(k)
  rs->RuleSystem.execute

  // Move in the dodging direction if set
  switch rs.state.dodgeDirection {
  | None => ()
  | Some(Left) => Pokemon.moveLeft(k, rs.state.enemy)
  | Some(Right) => Pokemon.moveRight(k, rs.state.enemy)
  }
}

let make = (k: Context.t, ~pokemonId: int, ~level: int, player: Pokemon.t): Pokemon.t => {
  let enemy: Pokemon.t = Pokemon.make(k, ~pokemonId, ~level, Opponent)
  let rs = makeRuleSystem(k, ~enemy, ~player)

  enemy->Pokemon.onUpdate(update(k, rs, ...))

  DebugRuleSystem.make(k, rs)

  enemy
}
