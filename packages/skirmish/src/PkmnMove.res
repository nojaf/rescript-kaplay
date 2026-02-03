open Kaplay

// Fact names for all 4 move slots
let move0Facts: Pokemon.moveFactNames = {
  available: RuleSystem.Fact("move-0-available"),
  successRate: RuleSystem.Fact("move-0-success-rate"),
}

let move1Facts: Pokemon.moveFactNames = {
  available: RuleSystem.Fact("move-1-available"),
  successRate: RuleSystem.Fact("move-1-success-rate"),
}

let move2Facts: Pokemon.moveFactNames = {
  available: RuleSystem.Fact("move-2-available"),
  successRate: RuleSystem.Fact("move-2-success-rate"),
}

let move3Facts: Pokemon.moveFactNames = {
  available: RuleSystem.Fact("move-3-available"),
  successRate: RuleSystem.Fact("move-3-success-rate"),
}

/** Create a moveSlot from a move definition with full PP and no cooldown */
let makeMoveSlot = (move: Pokemon.move): Pokemon.moveSlot => {
  move,
  currentPP: move.maxPP,
  lastUsedAt: neg_infinity,
}

/** Check if a move slot can be cast based on PP and cooldown */
let canCast = (slot: Pokemon.moveSlot, currentTime: float): bool => {
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
  rs: RuleSystem.t<Pokemon.ruleSystemState>,
  moveSlot: Pokemon.moveSlot,
  factNames: Pokemon.moveFactNames,
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
