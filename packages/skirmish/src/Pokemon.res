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
  team: Team.t,
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

/** Recalculate which moves are available and restore attack status.
    Call this after a move's cooldown finishes. */
let finishAttack = (pokemon: t): unit => {
  // TODO: Check PP and cooldowns for each move slot
  // For now, just make all moves available again
  pokemon.attackStatus = CanAttack([0, 1, 2, 3])
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
    Handles setting attackStatus to CannotAttack before invoking the move's cast function. */
let tryCastMove = (k: Context.t, pokemon: t, moveIndex: int): unit => {
  switch pokemon.attackStatus {
  | CannotAttack => ()
  | CanAttack(availableMoves) if availableMoves->Array.includes(moveIndex) =>
    switch getMoveSlot(pokemon, moveIndex) {
    | None => ()
    | Some(slot) =>
      pokemon.attackStatus = CannotAttack
      slot.move.cast(k, pokemon->toAbstractPkmn)
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
  team: Team.t,
): t => {
  let moveSlot1 = PkmnMove.makeMoveSlot(move1)
  let moveSlot2 = PkmnMove.makeMoveSlot(move2)
  let moveSlot3 = PkmnMove.makeMoveSlot(move3)
  let moveSlot4 = PkmnMove.makeMoveSlot(move4)
  let (spriteName, direction, posY) = if team == Player {
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

  let gameObj: t = k->Context.add([
    // initialState
    internalState({
      direction,
      level,
      pokemonId,
      team,
      facing: FacingUp,
      mobility: CanMove,
      attackStatus: CanAttack([0, 1, 2, 3]),
      halfSize,
      squaredPersonalSpace,
      moveSlot1,
      moveSlot2,
      moveSlot3,
      moveSlot4,
    }),
    k->addPos(k->Context.center->Vec2.World.x, posY),
    k->addSprite(spriteName),
    team == Player ? Team.playerTagComponent : Team.opponentTagComponent,
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
    k->Context.go(GameOver.sceneName, ~data=gameObj.team)
  })

  gameObj
}
