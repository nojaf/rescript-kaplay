open Kaplay

@unboxed
type horizontalMovement = | @as(true) Left | @as(false) Right

type ruleSystemState = {
  enemy: Pokemon.t,
  player: Pokemon.t,
  mutable playerAttacks: array<Attack.Unit.t>,
  mutable horizontalMovement: option<horizontalMovement>,
  lastAttackAt: float,
}

let overlapX = ((ax1, ax2), (bx1, bx2)) => {
  Stdlib_Math.max(ax1, bx1) <= Stdlib_Math.min(ax2, bx2)
}

module BaseFacts = {
  open RuleSystem

  let salience = Salience(0.0)

  // Attack positions
  let attackInCenterOfEnemy = Fact("attackInCenterOfEnemy")
  let attackOnTheLeftOfEnemy = Fact("attackOnTheLeftOfEnemy")
  let attackOnTheRightOfEnemy = Fact("attackOnTheRightOfEnemy")

  // Space availability
  let hasSpaceOnTheLeft = Fact("hasSpaceOnTheLeft")
  let hasSpaceOnTheRight = Fact("hasSpaceOnTheRight")

  // Player position relative to enemy
  let isPlayerLeft = Fact("isPlayerLeft")
  let isPlayerRight = Fact("isPlayerRight")

  let addRules = (
    k: Context.t,
    rs: RuleSystem.t<ruleSystemState>,
  ) => {
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
          rs->RuleSystem.assertFact(attackOnTheLeftOfEnemy, ~grade=leftGrade.contents)
        }
        if rightGrade.contents > RuleSystem.Grade(0.) {
          rs->RuleSystem.assertFact(attackOnTheRightOfEnemy, ~grade=rightGrade.contents)
        }
        if centerGrade.contents > RuleSystem.Grade(0.) {
          rs->RuleSystem.assertFact(attackInCenterOfEnemy, ~grade=centerGrade.contents)
        }
      },
      ~salient=salience,
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
          rs->RuleSystem.assertFact(hasSpaceOnTheLeft, ~grade=RuleSystem.Grade(leftSpace))
        }
        if rightSpace > 0. {
          rs->RuleSystem.assertFact(hasSpaceOnTheRight, ~grade=RuleSystem.Grade(rightSpace))
        }
      },
      ~salient=salience,
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
          rs->RuleSystem.assertFact(isPlayerLeft, ~grade=RuleSystem.Grade(1.0))
        } else {
          // Player is to the right
          rs->RuleSystem.assertFact(isPlayerRight, ~grade=RuleSystem.Grade(1.0))
        }
      },
      ~salient=salience,
    )
  }
}

module DerivedFacts = {
  open RuleSystem

  let salience = Salience(10.0)

  // Threat levels (computed from attack facts)
  let leftThreat = Fact("leftThreat")
  let rightThreat = Fact("rightThreat")

  let addRules = (rs: RuleSystem.t<ruleSystemState>) => {
    // Derived fact: Threat levels (depends on attack facts)
    rs->RuleSystem.addRuleExecutingAction(
      rs => {
        // Compute threats when we have attack information
        let RuleSystem.Grade(centerAttack) = RuleSystem.gradeForFact(rs, BaseFacts.attackInCenterOfEnemy)
        let RuleSystem.Grade(leftAttack) = RuleSystem.gradeForFact(rs, BaseFacts.attackOnTheLeftOfEnemy)
        let RuleSystem.Grade(rightAttack) = RuleSystem.gradeForFact(rs, BaseFacts.attackOnTheRightOfEnemy)
        centerAttack > 0.0 || leftAttack > 0.0 || rightAttack > 0.0
      },
      rs => {
        let RuleSystem.Grade(centerAttack) = RuleSystem.gradeForFact(rs, BaseFacts.attackInCenterOfEnemy)
        let RuleSystem.Grade(leftAttack) = RuleSystem.gradeForFact(rs, BaseFacts.attackOnTheLeftOfEnemy)
        let RuleSystem.Grade(rightAttack) = RuleSystem.gradeForFact(rs, BaseFacts.attackOnTheRightOfEnemy)

        // Left side threat = attacks on left + center (if center exists)
        let leftThreatGrade = leftAttack + centerAttack
        // Right side threat = attacks on right + center (if center exists)
        let rightThreatGrade = rightAttack + centerAttack

        if leftThreatGrade > 0.0 {
          rs->RuleSystem.assertFact(leftThreat, ~grade=RuleSystem.Grade(leftThreatGrade))
        }
        if rightThreatGrade > 0.0 {
          rs->RuleSystem.assertFact(rightThreat, ~grade=RuleSystem.Grade(rightThreatGrade))
        }
      },
      ~salient=salience,
    )
  }
}

module DecisionsFacts = {
  open RuleSystem
  let salience = Salience(20.0)

  // Preferred dodge direction
  let preferredDodgeLeft = Fact("preferredDodgeLeft")
  let preferredDodgeRight = Fact("preferredDodgeRight")

  let addRules = (rs: RuleSystem.t<ruleSystemState>) => {
    // Decision fact: Preferred dodge direction based on threats
    rs->RuleSystem.addRuleExecutingAction(
      rs => {
        // Only compute preferred direction when we have threat information
        let RuleSystem.Grade(leftThreat) = RuleSystem.gradeForFact(rs, DerivedFacts.leftThreat)
        let RuleSystem.Grade(rightThreat) = RuleSystem.gradeForFact(rs, DerivedFacts.rightThreat)
        leftThreat > 0.0 || rightThreat > 0.0
      },
      rs => {
        let RuleSystem.Grade(leftThreat) = RuleSystem.gradeForFact(rs, DerivedFacts.leftThreat)
        let RuleSystem.Grade(rightThreat) = RuleSystem.gradeForFact(rs, DerivedFacts.rightThreat)
        let RuleSystem.Grade(leftSpace) = RuleSystem.gradeForFact(rs, BaseFacts.hasSpaceOnTheLeft)
        let RuleSystem.Grade(rightSpace) = RuleSystem.gradeForFact(rs, BaseFacts.hasSpaceOnTheRight)

        if leftThreat > rightThreat {
          // More threat on left → prefer moving right
          rs->RuleSystem.assertFact(preferredDodgeRight, ~grade=RuleSystem.Grade(1.0))
        } else if rightThreat > leftThreat {
          // More threat on right → prefer moving left
          rs->RuleSystem.assertFact(preferredDodgeLeft, ~grade=RuleSystem.Grade(1.0))
        } // Equal threats (only center attack) - pick based on space
        else if leftSpace > rightSpace {
          rs->RuleSystem.assertFact(preferredDodgeLeft, ~grade=RuleSystem.Grade(1.0))
        } else {
          rs->RuleSystem.assertFact(preferredDodgeRight, ~grade=RuleSystem.Grade(1.0))
        }
      },
      ~salient=salience,
    )

    // Decision: Dodge when there's a center attack
    rs->RuleSystem.addRuleExecutingAction(
      rs => {
        // Only dodge when there's an attack in the center (or center + sides)
        // Side attacks alone don't require dodging
        let RuleSystem.Grade(c) = RuleSystem.gradeForFact(rs, BaseFacts.attackInCenterOfEnemy)
        c > 0.0
      },
      rs => {
        // Read decision facts (computed at salience 20.0)
        let RuleSystem.Grade(preferLeft) = RuleSystem.gradeForFact(rs, preferredDodgeLeft)
        let RuleSystem.Grade(preferRight) = RuleSystem.gradeForFact(rs, preferredDodgeRight)
        let RuleSystem.Grade(leftSpace) = RuleSystem.gradeForFact(rs, BaseFacts.hasSpaceOnTheLeft)
        let RuleSystem.Grade(rightSpace) = RuleSystem.gradeForFact(rs, BaseFacts.hasSpaceOnTheRight)

        // Determine preferred direction from facts
        let preferredDirection = if preferLeft > 0.0 {
          Left
        } else if preferRight > 0.0 {
          Right
        } // Fallback: pick based on space (shouldn't happen if threats computed correctly)
        else if leftSpace > rightSpace {
          Left
        } else {
          Right
        }

        // Check if we have space in the preferred direction
        let hasSpaceInPreferred = switch preferredDirection {
        | Left => leftSpace > 0.0
        | Right => rightSpace > 0.0
        }

        // Determine final direction considering space availability
        let finalDirection = if hasSpaceInPreferred {
          preferredDirection
        } else {
          // No space in preferred direction, try the other side
          switch preferredDirection {
          | Left => rightSpace > 0.0 ? Right : Left
          | Right => leftSpace > 0.0 ? Left : Right
          }
        }

        // Handle oscillation prevention for equal threats
        // If threats are equal and we already have a direction, keep it to avoid oscillation
        let RuleSystem.Grade(leftThreat) = RuleSystem.gradeForFact(rs, DerivedFacts.leftThreat)
        let RuleSystem.Grade(rightThreat) = RuleSystem.gradeForFact(rs, DerivedFacts.rightThreat)
        let threatsAreEqual = leftThreat == rightThreat && leftThreat > 0.0

        switch rs.state.horizontalMovement {
        | None =>
          // Pick initial direction
          rs.state.horizontalMovement = Some(finalDirection)
        | Some(currentDirection) =>
          if threatsAreEqual {
            // Keep current direction to avoid oscillation when threats are equal
            ()
          } else if currentDirection != finalDirection {
            // Update direction when threats are different
            rs.state.horizontalMovement = Some(finalDirection)
          } else {
            // Direction unchanged
            ()
          }
        }
      },
      ~salient=salience,
    )

    // Rule: Reset horizontal movement when center attack is gone
    // We stop dodging once we've successfully dodged the center attack,
    // even if there are still attacks on the sides
    rs->RuleSystem.addRuleExecutingAction(
      rs => {
        let RuleSystem.Grade(c) = RuleSystem.gradeForFact(rs, BaseFacts.attackInCenterOfEnemy)
        c == 0.0
      },
      rs => {
        rs.state.horizontalMovement = None
      },
      ~salient=salience,
    )

    // Decision: Position in front of player when there are no attacks
    rs->RuleSystem.addRuleExecutingAction(
      rs => {
        // Only position when there are no player attacks
        rs.state.playerAttacks->Array.length == 0
      },
      rs => {
        // Read player position facts (computed at salience 0.0)
        let RuleSystem.Grade(playerLeft) = RuleSystem.gradeForFact(rs, BaseFacts.isPlayerLeft)
        let RuleSystem.Grade(playerRight) = RuleSystem.gradeForFact(rs, BaseFacts.isPlayerRight)
        let RuleSystem.Grade(leftSpace) = RuleSystem.gradeForFact(rs, BaseFacts.hasSpaceOnTheLeft)
        let RuleSystem.Grade(rightSpace) = RuleSystem.gradeForFact(rs, BaseFacts.hasSpaceOnTheRight)

        if playerLeft > 0.0 {
          // Player is left, move left if we have space
          rs.state.horizontalMovement = leftSpace > 0.0 ? Some(Left) : None
        } else if playerRight > 0.0 {
          // Player is right, move right if we have space
          rs.state.horizontalMovement = rightSpace > 0.0 ? Some(Right) : None
        } else {
          // Neither fact is true - we're aligned (horizontalDistance == 0.0), stop moving
          rs.state.horizontalMovement = None
        }
      },
      ~salient=salience,
    )
  }
}

/** Creates a rule system for enemy AI behavior.
  *
  * **Important**: The rule system is reset on every update (see `update` function).
  * This means all facts are cleared before each execution cycle. As a result, you
  * typically should NOT use `assertFact`/`retractFact` pairs for state management.
  * Instead, use `addRuleAssertingFact` or `addRuleExecutingAction` with `assertFact`
  * to compute facts fresh each frame based on current game state.
  */
let makeRuleSystem = (k: Context.t, ~enemy: Pokemon.t, ~player: Pokemon.t): RuleSystem.t<
  ruleSystemState,
> => {
  let rs = RuleSystem.make(k)
  rs.state = {
    enemy,
    player,
    playerAttacks: [],
    horizontalMovement: None,
    lastAttackAt: 0.,
  }

  BaseFacts.addRules(k, rs)
  DerivedFacts.addRules(rs)
  DecisionsFacts.addRules(rs)

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

  // Move in the horizontal movement direction if set
  switch rs.state.horizontalMovement {
  | None => ()
  | Some(Left) => Pokemon.moveLeft(k, rs.state.enemy)
  | Some(Right) => Pokemon.moveRight(k, rs.state.enemy)
  }
}

let make = (k: Context.t, ~pokemonId: int, ~level: int, player: Pokemon.t): Pokemon.t => {
  let enemy: Pokemon.t = Pokemon.make(k, ~pokemonId, ~level, Opponent)
  let rs = makeRuleSystem(k, ~enemy, ~player)

  enemy->Pokemon.onUpdate(update(k, rs, ...))

  if k.debug.inspect {
    DebugRuleSystem.make(k, rs)
  }

  enemy
}
