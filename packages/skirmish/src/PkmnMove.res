open Kaplay

type pkmn

type enemyAIRuleSystemState

type moveFactNames = {
  available: RuleSystem.fact, // e.g., "move-1-available"
  successRate: RuleSystem.fact, // e.g., "move-1-success-rate"
  // Add more as needed
}

// The move definition type (singleton instance per move type)
type rec t = {
  id: int, // Unique identifier (manually assigned per move)
  name: string,
  maxPP: int,
  baseDamage: int,
  coolDownDuration: float,
  // Execute the move
  cast: (Context.t, pkmn) => unit,
  // Add AI rules for this move to the rule system
  // prefix: e.g., "move-1", "move-2" - used to namespace facts
  // moveState: current PP and last used time
  // ruleSystemState: full game state for AI evaluation
  addRulesForAI: (
    enemyAIRuleSystemState,
    moveSlot,
    enemyAIRuleSystemState,
    moveFactNames,
  ) => // Standard fact names to assert
  unit,
}

and moveSlot = {
  move: t,
  mutable currentPP: int,
  mutable lastUsedAt: float,
}
