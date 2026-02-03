open Kaplay

@unboxed
type facing = | @as(true) FacingUp | @as(false) FacingDown

@unboxed
type mobility = | @as(true) CanMove | @as(false) CannotMove

/** Track if we can attack and which moves are available */
@unboxed
type attackStatus =
  /** Currently executing a move */
  | CannotAttack
  /* Array of move indices (0-3) that are available */
  | CanAttack(array<int>)

@unboxed
type horizontalMovement = | @as(true) MoveLeft | @as(false) MoveRight

type moveFactNames = {
  available: RuleSystem.fact,
  successRate: RuleSystem.fact,
}

type rec t = {
  mutable direction: Vec2.Unit.t,
  mutable facing: facing,
  mutable mobility: mobility,
  mutable attackStatus: attackStatus,
  level: int,
  pokemonId: int,
  mutable team: option<Team.t>,
  /** Half size of the pokemon in world units */
  halfSize: float,
  /** Squared distance between the pokemon and what we consider its personal space
      This is used to determine how close a potential attack is to the pokemon's personal space.
   */
  squaredPersonalSpace: float,
  // Moves
  moveSlot1: moveSlot,
  moveSlot2: moveSlot,
  moveSlot3: moveSlot,
  moveSlot4: moveSlot,
}

and move = {
  id: int, // Unique identifier (manually assigned per move)
  name: string,
  maxPP: int,
  baseDamage: int,
  coolDownDuration: float,
  // Execute the move
  cast: (Context.t, t) => unit,
  // Add AI rules for this move to the rule system
  // k: Kaplay context (for getting current time, etc.)
  // ruleSystem: the rule system to add rules to
  // moveSlot: current PP and last used time for this move
  // factNames: standard fact names to assert (e.g., "move-0-available")
  addRulesForAI: (Context.t, RuleSystem.t<ruleSystemState>, moveSlot, moveFactNames) => unit,
}

and moveSlot = {
  move: move,
  mutable currentPP: int,
  mutable lastUsedAt: float,
}

and ruleSystemState = {
  enemy: t,
  player: t,
  mutable playerAttacks: array<Attack.Unit.t>,
  mutable horizontalMovement: option<horizontalMovement>,
  lastAttackAt: float,
}

include GameObjRaw.Comp({type t = t})
include Pos.Comp({type t = t})
include Sprite.Comp({type t = t})
include Area.Comp({type t = t})
include Health.Comp({type t = t})
include Anchor.Comp({type t = t})
include Shader.Comp({type t = t})
include Opacity.Comp({type t = t})
include Animate.Comp({type t = t})
include Body.Comp({type t = t})

let tag = "pokemon"
