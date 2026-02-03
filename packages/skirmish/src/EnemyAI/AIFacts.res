/** Shared fact definitions for AI rule systems.
  * This module defines all facts that can be used by both EnemyAI modules and individual moves.
  * Having them in one place breaks circular dependencies and provides a clear overview.
  */
open Kaplay

// === Base Facts (salience 0.0) ===
// Attack positions
let attackInCenterOfEnemy = RuleSystem.Fact("attackInCenterOfEnemy")
let attackOnTheLeftOfEnemy = RuleSystem.Fact("attackOnTheLeftOfEnemy")
let attackOnTheRightOfEnemy = RuleSystem.Fact("attackOnTheRightOfEnemy")

// Space availability
let hasSpaceOnTheLeft = RuleSystem.Fact("hasSpaceOnTheLeft")
let hasSpaceOnTheRight = RuleSystem.Fact("hasSpaceOnTheRight")

// Player position relative to enemy
let isPlayerLeft = RuleSystem.Fact("isPlayerLeft")
let isPlayerRight = RuleSystem.Fact("isPlayerRight")

// === Derived Facts (salience 10.0) ===
// Threat levels (computed from attack facts)
let leftThreat = RuleSystem.Fact("leftThreat")
let rightThreat = RuleSystem.Fact("rightThreat")

// === Defensive Facts (salience 20.0) ===
// Preferred dodge direction
let preferredDodgeLeft = RuleSystem.Fact("preferredDodgeLeft")
let preferredDodgeRight = RuleSystem.Fact("preferredDodgeRight")

// === Attack Facts (salience 30.0) ===
// Attack decision - asserted by move-specific rules
let shouldAttack = RuleSystem.Fact("shouldAttack")
