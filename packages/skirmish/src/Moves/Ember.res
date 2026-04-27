open Kaplay

type t

include GameObjRaw.Comp({type t = t})
include Sprite.Comp({type t = t})
include Pos.Comp({type t = t})
include Kaplay.Move.Comp({type t = t})
include Anchor.Comp({type t = t})
include Z.Comp({type t = t})
include Area.Comp({type t = t})
include Attack.Comp({type t = t})

let spriteName = "flame"

let load = (k: Context.t) => {
  k->Context.loadSprite(spriteName, "/sprites/moves/flame.png")
}

let coolDown = 1.

let cast = (k: Context.t, pokemon: Pokemon.t) => {
  // Use the pokemon's world position for the flame's position
  // Because flame is using the move component, it will move based on a direction vector relative to the parent.
  // That is why the pokemon cannot be the parent of the flame.
  let pokemonWorldPos = pokemon->Pokemon.worldPos
  let direction = pokemon.facing == FacingUp ? k->Context.vec2Up : k->Context.vec2Down

  let flame: t = k->Context.add(
    [
      addSprite(k, spriteName),
      addPosFromWorldVec2(k, pokemonWorldPos),
      addMove(k, direction, 120.),
      addZ(k, -1),
      addArea(k),
      pokemon.facing == FacingUp ? addAnchorBottom(k) : addAnchorTop(k),
      Team.getTagComponent(pokemon->Pkmn.getTeam),
      ...addAttackWithTag(@this (flame: t) => {
        Kaplay.Math.Rect.makeWorld(k, flame->worldPos, flame->getWidth, flame->getHeight)
      }),
    ],
  )

  flame->onCollide(Pokemon.tag, (other: Pokemon.t, _collision) => {
    if other.pokemonId != pokemon.pokemonId {
      Console.log2("Ember hit", other.pokemonId)
      other->Pokemon.setHp(other->Pokemon.getHp - 5)
      flame->destroy
    }
  })

  flame->onCollide(Wall.tag, (_: Wall.t, _collision) => {
    flame->destroy
  })
}

let addRulesForAI = (
  _k: Context.t,
  rs: RuleSystem.t<Pokemon.ruleSystemState>,
  _moveSlot: Pokemon.moveSlot,
  factNames: Pokemon.moveFactNames,
) => {
  // Ember attacks when safe: not under threat and move is available
  rs->RuleSystem.addRuleExecutingAction(
    rs => {
      // Check if not under threat (both preferred dodge facts should be 0.0)
      let RuleSystem.Grade(preferLeft) = rs->RuleSystem.gradeForFact(AIFacts.preferredDodgeLeft)
      let RuleSystem.Grade(preferRight) = rs->RuleSystem.gradeForFact(AIFacts.preferredDodgeRight)
      let notUnderThreat = preferLeft == 0.0 && preferRight == 0.0

      // Check if this move is available
      let RuleSystem.Grade(available) = rs->RuleSystem.gradeForFact(factNames.available)
      let moveAvailable = available > 0.0

      notUnderThreat && moveAvailable
    },
    rs => {
      rs->RuleSystem.assertFact(AIFacts.shouldAttack)
    },
    ~salience=RuleSystem.Salience(30.0),
  )
}

let move: Pokemon.move = {
  id: 1,
  name: "Ember",
  maxPP: 25,
  baseDamage: 40,
  coolDownDuration: coolDown,
  cast,
  addRulesForAI,
}
