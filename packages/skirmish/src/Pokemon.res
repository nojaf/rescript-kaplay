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

type t = {
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
  moveSlot1: PkmnMove.moveSlot,
  moveSlot2: PkmnMove.moveSlot,
  moveSlot3: PkmnMove.moveSlot,
  moveSlot4: PkmnMove.moveSlot,
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

/* Helpers to consistently compose sprite names and URLs from an id */
let frontSpriteName = (id: int) => "pokemon-" ++ Int.toString(id) ++ "-front"
let backSpriteName = (id: int) => "pokemon-" ++ Int.toString(id) ++ "-back"

let frontSpriteUrl = (id: int) => `/sprites/${Int.toString(id)}-front.png`
let backSpriteUrl = (id: int) => `/sprites/${Int.toString(id)}-back.png`

/* Load both front and back sprites for the given pokemon id */
let load = (k: Context.t, id: int): unit => {
  k->Context.loadSprite(frontSpriteName(id), frontSpriteUrl(id), ~options={singular: true})
  k->Context.loadSprite(backSpriteName(id), backSpriteUrl(id), ~options={singular: true})
}

let movementSpeed = 200.

external internalState: t => Types.comp = "%identity"

let getHealthPercentage = (pokemon: t): float => {
  let currentHp = pokemon->getHp->Int.toFloat
  let maxHp = pokemon->getMaxHp->Int.toFloat
  currentHp / maxHp * 100.
}

let moveLeft = (k: Context.t, pokemon: t) => {
  pokemon->move(k->Context.vec2World(-100., 0.))
}

let moveRight = (k: Context.t, pokemon: t) => {
  pokemon->move(k->Context.vec2World(100., 0.))
}

/** Compute which move indices (0-3) are available based on PP and cooldown */
let getAvailableMoveIndices = (
  slot1: PkmnMove.moveSlot,
  slot2: PkmnMove.moveSlot,
  slot3: PkmnMove.moveSlot,
  slot4: PkmnMove.moveSlot,
  currentTime: float,
): array<int> => {
  let moves = []
  if PkmnMove.canCast(slot1, currentTime) {
    moves->Array.push(0)
  }
  if PkmnMove.canCast(slot2, currentTime) {
    moves->Array.push(1)
  }
  if PkmnMove.canCast(slot3, currentTime) {
    moves->Array.push(2)
  }
  if PkmnMove.canCast(slot4, currentTime) {
    moves->Array.push(3)
  }
  moves
}

/** Recalculate which moves are available and restore attack status.
    Call this after a move's cooldown finishes. */
let finishAttack = (k: Kaplay.Context.t, pokemon: t): unit => {
  let currentTime = k->Kaplay.Context.time
  let availableMoves = getAvailableMoveIndices(
    pokemon.moveSlot1,
    pokemon.moveSlot2,
    pokemon.moveSlot3,
    pokemon.moveSlot4,
    currentTime,
  )
  pokemon.attackStatus = CanAttack(availableMoves)
}

/** Schedule finishAttack to be called after a cooldown duration.
    Common pattern used by moves after their animation/effect completes. */
let scheduleFinishAttack = (k: Kaplay.Context.t, pokemon: t, cooldown: float): unit => {
  k->Kaplay.Context.wait(cooldown, () => {
    finishAttack(k, pokemon)
  })
}

/** Check if the pokemon can attack */
let canAttack = (pokemon: t): bool => {
  switch pokemon.attackStatus {
  | CannotAttack => false
  | CanAttack(_) => true
  }
}

/** Get move slot by index (0-3) */
let getMoveSlot = (pokemon: t, index: int): option<PkmnMove.moveSlot> => {
  switch index {
  | 0 => Some(pokemon.moveSlot1)
  | 1 => Some(pokemon.moveSlot2)
  | 2 => Some(pokemon.moveSlot3)
  | 3 => Some(pokemon.moveSlot4)
  | _ => None
  }
}

external toAbstractPkmn: t => PkmnMove.pkmn = "%identity"
external fromAbstractPkmn: PkmnMove.pkmn => t = "%identity"

/** Try to cast a move by index (0-3).
    Handles setting attackStatus to CannotAttack before invoking the move's cast function.
    Automatically schedules finishAttack after the move's cooldown duration. */
let tryCastMove = (k: Context.t, pokemon: t, moveIndex: int): unit => {
  switch pokemon.attackStatus {
  | CannotAttack => ()
  | CanAttack(availableMoves) if availableMoves->Array.includes(moveIndex) =>
    switch getMoveSlot(pokemon, moveIndex) {
    | None => ()
    | Some(slot) =>
      // Decrement PP and record usage time
      slot.currentPP = slot.currentPP - 1
      slot.lastUsedAt = k->Context.time
      pokemon.attackStatus = CannotAttack
      slot.move.cast(k, pokemon->toAbstractPkmn)
      // Automatically restore attack status after cooldown
      scheduleFinishAttack(k, pokemon, slot.move.coolDownDuration)
    }
  | CanAttack(_) => ()
  }
}

let make = (
  k: Context.t,
  ~pokemonId: int,
  ~level: int,
  ~move1: PkmnMove.t=ZeroMove.move,
  ~move2: PkmnMove.t=ZeroMove.move,
  ~move3: PkmnMove.t=ZeroMove.move,
  ~move4: PkmnMove.t=ZeroMove.move,
  ~facing: facing,
): t => {
  let moveSlot1 = PkmnMove.makeMoveSlot(move1)
  let moveSlot2 = PkmnMove.makeMoveSlot(move2)
  let moveSlot3 = PkmnMove.makeMoveSlot(move3)
  let moveSlot4 = PkmnMove.makeMoveSlot(move4)
  let (spriteName, direction, posY) = if facing == FacingUp {
    (backSpriteName(pokemonId), k->Context.vec2Up, k->Context.height * 0.75)
  } else {
    (frontSpriteName(pokemonId), k->Context.vec2Down, k->Context.height * 0.25)
  }
  let (halfSize, squaredPersonalSpace) = switch Context.getSprite(k, spriteName).data {
  | Null.Null => (0., 0.)
  | Null.Value(sprite) => {
      let halfSize = sprite->SpriteData.width / 2.
      // Twice the radius of a circle around the sprite.
      let squaredPersonalSpace = halfSize * halfSize * halfSize
      (halfSize, squaredPersonalSpace)
    }
  }

  let currentTime = k->Context.time
  let initialAvailableMoves = getAvailableMoveIndices(
    moveSlot1,
    moveSlot2,
    moveSlot3,
    moveSlot4,
    currentTime,
  )

  let gameObj: t = k->Context.add([
    // initialState
    internalState({
      direction,
      level,
      pokemonId,
      team: None,
      facing,
      mobility: CanMove,
      attackStatus: CanAttack(initialAvailableMoves),
      halfSize,
      squaredPersonalSpace,
      moveSlot1,
      moveSlot2,
      moveSlot3,
      moveSlot4,
    }),
    k->addPos(k->Context.center->Vec2.World.x, posY),
    k->addSprite(spriteName),
    k->addArea,
    k->addBody,
    k->addHealth(20, ~maxHP=20),
    k->addAnchorCenter,
    k->addOpacity(1.),
    k->addAnimate,
    Context.tag(tag),
    CustomComponent.make({
      id: "pokemon",
      drawInspect: @this
      (gameObj: t) => {
        let radius = Stdlib_Math.sqrt(gameObj.squaredPersonalSpace)
        k->Context.drawCircle({
          radius,
          opacity: 0.1,
          outline: {
            color: k->Color.magenta,
            width: 2.,
          },
        })
      },
    }),
  ])

  gameObj->onHurt((_deltaHp: int) => {
    // Stop any existing opacity animation and reset the internal clock
    gameObj->unanimate("opacity")
    gameObj->getAnimation->(animation => animation.seek(0.))
    // Animate opacity: 1.0 → 0.5 → 0.75 → 1.0
    gameObj->animate(
      "opacity",
      [1., 0.3, 1., 0.5, 1.],
      {
        duration: 0.4,
        loops: 1,
      },
    )
  })

  gameObj->onDeath(() => {
    // Team is guaranteed to be assigned before death can occur
    k->Context.go(GameOver.sceneName, ~data=gameObj.team->Option.getOrThrow)
  })

  gameObj
}

/** Assign the player team to the pokemon and add the corresponding tag component. */
let assignPlayer = (pokemon: t): unit => {
  pokemon.team = Some(Team.Player)
  pokemon->addTag(Team.player)
}

/** Assign the opponent team to the pokemon and add the corresponding tag component. */
let assignOpponent = (pokemon: t): unit => {
  pokemon.team = Some(Team.Opponent)
  pokemon->addTag(Team.opponent)
}

/** Get the team, panicking if not assigned. Only call after assignTeam. */
let getTeam = (pokemon: t): Team.t => {
  switch pokemon.team {
  | Some(team) => team
  | None => JsError.throwWithMessage("Pokemon team not assigned")
  }
}
