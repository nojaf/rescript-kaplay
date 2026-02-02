open Kaplay

/** Represents Pokemon.t without depending on Pokemon.res */
type pkmn
/**  Represents EnemyAIRuleSystemState.t without depending on EnemyAIRuleSystemState.res */
type enemyAIRuleSystemState

type moveFactNames = {
  available: RuleSystem.fact,
  successRate: RuleSystem.fact,
}

// Fact names for all 4 move slots
let move0Facts: moveFactNames = {
  available: RuleSystem.Fact("move-0-available"),
  successRate: RuleSystem.Fact("move-0-success-rate"),
}

let move1Facts: moveFactNames = {
  available: RuleSystem.Fact("move-1-available"),
  successRate: RuleSystem.Fact("move-1-success-rate"),
}

let move2Facts: moveFactNames = {
  available: RuleSystem.Fact("move-2-available"),
  successRate: RuleSystem.Fact("move-2-success-rate"),
}

let move3Facts: moveFactNames = {
  available: RuleSystem.Fact("move-3-available"),
  successRate: RuleSystem.Fact("move-3-success-rate"),
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
  // k: Kaplay context (for getting current time, etc.)
  // ruleSystem: the rule system to add rules to
  // moveSlot: current PP and last used time for this move
  // factNames: standard fact names to assert (e.g., "move-0-available")
  addRulesForAI: (Context.t, RuleSystem.t<enemyAIRuleSystemState>, moveSlot, moveFactNames) => unit,
}

and moveSlot = {
  move: t,
  mutable currentPP: int,
  mutable lastUsedAt: float,
}

/** Create a moveSlot from a move definition with full PP and no cooldown */
let makeMoveSlot = (move: t): moveSlot => {
  move,
  currentPP: move.maxPP,
  lastUsedAt: neg_infinity,
}

/** Check if a move slot can be cast based on PP and cooldown */
let canCast = (slot: moveSlot, currentTime: float): bool => {
  // Must have PP remaining
  slot.currentPP > 0 &&
  // Must not be a ZeroMove (empty slot)
  slot.move.id != -1 &&
  // Cooldown must have elapsed
  currentTime - slot.lastUsedAt >= slot.move.coolDownDuration
}

/** Default AI rules that apply to all moves: assert availability when canCast is true */
let defaultAddRulesForAI = (
  k: Context.t,
  rs: RuleSystem.t<enemyAIRuleSystemState>,
  moveSlot: moveSlot,
  factNames: moveFactNames,
) => {
  rs->RuleSystem.addRuleExecutingAction(
    _rs => {
      let currentTime = k->Context.time
      canCast(moveSlot, currentTime)
    },
    rs => {
      rs->RuleSystem.assertFact(factNames.available)
    },
    ~salience=RuleSystem.Salience(25.0),
  )
}
