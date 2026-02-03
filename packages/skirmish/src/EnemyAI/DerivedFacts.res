/** Derived facts module for enemy AI.
  *
  * This module computes derived facts based on facts from BaseFacts module.
  * It aggregates attack information into threat levels (leftThreat, rightThreat)
  * that combine information about attacks from different directions. These threat
  * facts are used by DefensiveFacts module to determine defensive behavior.
  */
open Kaplay

let salience = RuleSystem.Salience(10.0)

let addRules = (rs: RuleSystem.t<Pokemon.ruleSystemState>) => {
  // Derived fact: Threat levels (depends on attack facts)
  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      // Compute threats when we have attack information
      let RuleSystem.Grade(centerAttack) = RuleSystem.gradeForFact(
        rs,
        AIFacts.attackInCenterOfEnemy,
      )
      let RuleSystem.Grade(leftAttack) = RuleSystem.gradeForFact(rs, AIFacts.attackOnTheLeftOfEnemy)
      let RuleSystem.Grade(rightAttack) = RuleSystem.gradeForFact(
        rs,
        AIFacts.attackOnTheRightOfEnemy,
      )
      centerAttack > 0.0 || leftAttack > 0.0 || rightAttack > 0.0
    },
    rs => {
      let RuleSystem.Grade(centerAttack) = RuleSystem.gradeForFact(
        rs,
        AIFacts.attackInCenterOfEnemy,
      )
      let RuleSystem.Grade(leftAttack) = RuleSystem.gradeForFact(rs, AIFacts.attackOnTheLeftOfEnemy)
      let RuleSystem.Grade(rightAttack) = RuleSystem.gradeForFact(
        rs,
        AIFacts.attackOnTheRightOfEnemy,
      )

      // Left side threat = attacks on left + center (if center exists)
      let leftThreatGrade = leftAttack + centerAttack
      // Right side threat = attacks on right + center (if center exists)
      let rightThreatGrade = rightAttack + centerAttack

      if leftThreatGrade > 0.0 {
        rs->RuleSystem.assertFact(AIFacts.leftThreat, ~grade=RuleSystem.Grade(leftThreatGrade))
      }
      if rightThreatGrade > 0.0 {
        rs->RuleSystem.assertFact(AIFacts.rightThreat, ~grade=RuleSystem.Grade(rightThreatGrade))
      }
    },
    ~salience,
  )
}
