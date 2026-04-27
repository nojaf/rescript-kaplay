open Kaplay
open Pokemon

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
  slot1: Pokemon.moveSlot,
  slot2: Pokemon.moveSlot,
  slot3: Pokemon.moveSlot,
  slot4: Pokemon.moveSlot,
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

let dispatch = (pokemon: t, event: Pokemon.event): unit => {
  pokemon.eventQueue->Belt.MutableQueue.add(event)
}

let delayedDispatch = (
  k: Kaplay.Context.t,
  pokemon: t,
  event: Pokemon.event,
  delay: float,
): unit => {
  k->Kaplay.Context.wait(delay, () => {
    pokemon->dispatch(event)
  })
}

/** Get move slot by index (0-3) */
let getMoveSlot = (pokemon: t, index: int): option<Pokemon.moveSlot> => {
  switch index {
  | 0 => Some(pokemon.moveSlot1)
  | 1 => Some(pokemon.moveSlot2)
  | 2 => Some(pokemon.moveSlot3)
  | 3 => Some(pokemon.moveSlot4)
  | _ => None
  }
}

/** Process all pending events in the pokemon's event queue.
    Uses pop loop so events enqueued during processing (e.g. cast enqueues MobilityChanged) are handled immediately. */
let processEvents = (k: Kaplay.Context.t, pokemon: t): unit => {
  let break = ref(false)
  while !break.contents {
    switch pokemon.eventQueue->Belt.MutableQueue.pop {
    | None => break := true
    | Some(MoveCast(moveIndex)) =>
      switch getMoveSlot(pokemon, moveIndex) {
      | None => ()
      | Some(slot) =>
        slot.currentPP = slot.currentPP - 1
        slot.lastUsedAt = k->Kaplay.Context.time
        pokemon.attackStatus = CannotAttack
        slot.move.cast(k, pokemon)
        delayedDispatch(k, pokemon, CooldownFinished(moveIndex), slot.move.coolDownDuration)
      }
    | Some(CooldownFinished(_moveIndex)) =>
      let currentTime = k->Kaplay.Context.time
      let availableMoves = getAvailableMoveIndices(
        pokemon.moveSlot1,
        pokemon.moveSlot2,
        pokemon.moveSlot3,
        pokemon.moveSlot4,
        currentTime,
      )
      pokemon.attackStatus = CanAttack(availableMoves)
    | Some(MobilityChanged(mobility)) => pokemon.mobility = mobility
    | Some(FacingChanged(newFacing)) =>
      pokemon.facing = newFacing
      switch newFacing {
      | FacingUp =>
        pokemon->Pokemon.setSprite(backSpriteName(pokemon.pokemonId))
        pokemon.direction = k->Kaplay.Context.vec2Up
      | FacingDown =>
        pokemon->Pokemon.setSprite(frontSpriteName(pokemon.pokemonId))
        pokemon.direction = k->Kaplay.Context.vec2Down
      }
    }
  }
}

/** Try to cast a move by index (0-3).
    Validates the move is available and enqueues a MoveCast event. */
let tryCastMove = (pokemon: t, moveIndex: int): unit => {
  switch pokemon.attackStatus {
  | CannotAttack => ()
  | CanAttack(availableMoves) if availableMoves->Array.includes(moveIndex) =>
    pokemon->dispatch(MoveCast(moveIndex))
  | CanAttack(_) => ()
  }
}

let make = (
  k: Context.t,
  ~pokemonId: int,
  ~level: int,
  ~move1: Pokemon.move=ZeroMove.move,
  ~move2: Pokemon.move=ZeroMove.move,
  ~move3: Pokemon.move=ZeroMove.move,
  ~move4: Pokemon.move=ZeroMove.move,
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
      eventQueue: Belt.MutableQueue.make(),
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

  gameObj->onUpdate(() => processEvents(k, gameObj))

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
