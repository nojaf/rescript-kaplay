/** Defensive facts module for enemy AI.
  *
  * This module computes defensive decisions (dodging, positioning) based on facts
  * from BaseFacts and DerivedFacts modules. It uses facts about threats, space
  * availability, and player position to determine defensive movement.
  */
open Kaplay

let salience = RuleSystem.Salience(20.0)

let addRules = (rs: RuleSystem.t<Pokemon.ruleSystemState>) => {
  // Decision fact: Preferred dodge direction based on threats
  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      // Only compute preferred direction when we have threat information
      let RuleSystem.Grade(leftThreat) = RuleSystem.gradeForFact(rs, AIFacts.leftThreat)
      let RuleSystem.Grade(rightThreat) = RuleSystem.gradeForFact(rs, AIFacts.rightThreat)
      leftThreat > 0.0 || rightThreat > 0.0
    },
    rs => {
      let RuleSystem.Grade(leftThreat) = RuleSystem.gradeForFact(rs, AIFacts.leftThreat)
      let RuleSystem.Grade(rightThreat) = RuleSystem.gradeForFact(rs, AIFacts.rightThreat)
      let RuleSystem.Grade(leftSpace) = RuleSystem.gradeForFact(rs, AIFacts.hasSpaceOnTheLeft)
      let RuleSystem.Grade(rightSpace) = RuleSystem.gradeForFact(rs, AIFacts.hasSpaceOnTheRight)

      if leftThreat > rightThreat {
        // More threat on left → prefer moving right
        rs->RuleSystem.assertFact(AIFacts.preferredDodgeRight, ~grade=RuleSystem.Grade(1.0))
      } else if rightThreat > leftThreat {
        // More threat on right → prefer moving left
        rs->RuleSystem.assertFact(AIFacts.preferredDodgeLeft, ~grade=RuleSystem.Grade(1.0))
      } // Equal threats (only center attack) - pick based on space
      else if leftSpace > rightSpace {
        rs->RuleSystem.assertFact(AIFacts.preferredDodgeLeft, ~grade=RuleSystem.Grade(1.0))
      } else {
        rs->RuleSystem.assertFact(AIFacts.preferredDodgeRight, ~grade=RuleSystem.Grade(1.0))
      }
    },
    ~salience,
  )

  // Decision: Dodge when there's a center attack
  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      // Only dodge when there's an attack in the center (or center + sides)
      // Side attacks alone don't require dodging
      let RuleSystem.Grade(c) = RuleSystem.gradeForFact(rs, AIFacts.attackInCenterOfEnemy)
      c > 0.0
    },
    rs => {
      // Read decision facts (computed at salience 20.0)
      let RuleSystem.Grade(preferLeft) = RuleSystem.gradeForFact(rs, AIFacts.preferredDodgeLeft)
      let RuleSystem.Grade(preferRight) = RuleSystem.gradeForFact(rs, AIFacts.preferredDodgeRight)
      let RuleSystem.Grade(leftSpace) = RuleSystem.gradeForFact(rs, AIFacts.hasSpaceOnTheLeft)
      let RuleSystem.Grade(rightSpace) = RuleSystem.gradeForFact(rs, AIFacts.hasSpaceOnTheRight)

      // Determine preferred direction from facts
      let preferredDirection = if preferLeft > 0.0 {
        Pokemon.MoveLeft
      } else if preferRight > 0.0 {
        Pokemon.MoveRight
      } // Fallback: pick based on space (shouldn't happen if threats computed correctly)
      else if leftSpace > rightSpace {
        Pokemon.MoveLeft
      } else {
        Pokemon.MoveRight
      }

      // Check if we have space in the preferred direction
      let hasSpaceInPreferred = switch preferredDirection {
      | MoveLeft => leftSpace > 0.0
      | MoveRight => rightSpace > 0.0
      }

      // Determine final direction considering space availability
      let finalDirection = if hasSpaceInPreferred {
        preferredDirection
      } else {
        // No space in preferred direction, try the other side
        switch preferredDirection {
        | MoveLeft => rightSpace > 0.0 ? Pokemon.MoveRight : Pokemon.MoveLeft
        | MoveRight => leftSpace > 0.0 ? Pokemon.MoveLeft : Pokemon.MoveRight
        }
      }

      // Handle oscillation prevention for equal threats
      // If threats are equal and we already have a direction, keep it to avoid oscillation
      let RuleSystem.Grade(leftThreat) = RuleSystem.gradeForFact(rs, AIFacts.leftThreat)
      let RuleSystem.Grade(rightThreat) = RuleSystem.gradeForFact(rs, AIFacts.rightThreat)
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
    ~salience,
  )

  // Rule: Reset horizontal movement when center attack is gone
  // We stop dodging once we've successfully dodged the center attack,
  // even if there are still attacks on the sides
  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      let RuleSystem.Grade(c) = RuleSystem.gradeForFact(rs, AIFacts.attackInCenterOfEnemy)
      c == 0.0
    },
    rs => {
      rs.state.horizontalMovement = None
    },
    ~salience,
  )

  // Decision: Position in front of player when there are no attacks
  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      // Only position when there are no player attacks
      rs.state.playerAttacks->Array.length == 0
    },
    rs => {
      // Read player position facts (computed at salience 0.0)
      let RuleSystem.Grade(playerLeft) = RuleSystem.gradeForFact(rs, AIFacts.isPlayerLeft)
      let RuleSystem.Grade(playerRight) = RuleSystem.gradeForFact(rs, AIFacts.isPlayerRight)
      let RuleSystem.Grade(leftSpace) = RuleSystem.gradeForFact(rs, AIFacts.hasSpaceOnTheLeft)
      let RuleSystem.Grade(rightSpace) = RuleSystem.gradeForFact(rs, AIFacts.hasSpaceOnTheRight)

      if playerLeft > 0.0 {
        // Player is left, move left if we have space
        rs.state.horizontalMovement = leftSpace > 0.0 ? Some(Pokemon.MoveLeft) : None
      } else if playerRight > 0.0 {
        // Player is right, move right if we have space
        rs.state.horizontalMovement = rightSpace > 0.0 ? Some(Pokemon.MoveRight) : None
      } else {
        // Neither fact is true - we're aligned (horizontalDistance == 0.0), stop moving
        rs.state.horizontalMovement = None
      }
    },
    ~salience,
  )
}
