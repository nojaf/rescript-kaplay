open Kaplay
open GameContext
module Math = Kaplay.Math

type t = {
  points: array<Vec2.World.t>,
  timerRef: Kaplay.TimerController.t,
  mutable worldRect: Types.rect<Vec2.World.t>,
}

include Pos.Comp({type t = t})
include Anchor.Comp({type t = t})
include GameObjRaw.Comp({type t = t})
include Z.Comp({type t = t})
include Shader.Comp({type t = t})
include Attack.Comp({type t = t})

@module("../../shaders/glow.frag?raw")
external glowSource: string = "default"

@module("../../shaders/outline2px.frag?raw")
external outline2pxSource: string = "default"

@module("../../shaders/darken.frag?raw")
external darkenSource: string = "default"

let load = (): unit => {
  k->Context.loadShader("glow", ~frag=glowSource)
  k->Context.loadShader("outline2px", ~frag=outline2pxSource)
  k->Context.loadShader("darken", ~frag=darkenSource)
}

let lighting = k->Color.fromHex("#fef9c2")

let draw =
  @this
  (t: t) => {
    // Convert world coordinates to local coordinates for drawing
    let localPoints = t.points->Array.map(point => t->fromWorld(point))
    k->Context.drawLines({
      pts: localPoints,
      width: 2.,
      color: lighting,
      cap: Square,
    })
  }

let drawInspect =
  @this
  (t: t) => {
    let rectInLocal = t->fromWorld(t.worldRect.pos)
    k->Context.drawRect({
      pos: rectInLocal,
      width: t.worldRect.width,
      height: t.worldRect.height,
      fill: false,
      outline: {
        width: 2.,
        color: k->Color.blue,
      },
    })
  }

// Add a new point at a fixed interval using a timer loop
let intervalSeconds = 0.050
let coolDown = 1.
let deviationOffset = 7.
let distance = 40.
// Scale unit direction vectors to create world coordinate offsets
let up: Vec2.World.t = k->Context.vec2Up->Vec2.Unit.asWorld->Vec2.World.scaleWith(distance)
let down: Vec2.World.t = k->Context.vec2Down->Vec2.Unit.asWorld->Vec2.World.scaleWith(distance)

external initialState: t => Types.comp = "%identity"

let expandRectWithPoint = (
  currentRect: Types.rect<Vec2.World.t>,
  newPoint: Vec2.World.t,
): Types.rect<Vec2.World.t> => {
  let currentMinX = currentRect.pos.x
  let currentMaxX = currentRect.pos.x + currentRect.width
  let currentMinY = currentRect.pos.y
  let currentMaxY = currentRect.pos.y + currentRect.height

  let newMinX = Stdlib_Math.min(currentMinX, newPoint.x)
  let newMaxX = Stdlib_Math.max(currentMaxX, newPoint.x)
  let newMinY = Stdlib_Math.min(currentMinY, newPoint.y)
  let newMaxY = Stdlib_Math.max(currentMaxY, newPoint.y)

  let newWidth = newMaxX - newMinX
  let newHeight = newMaxY - newMinY

  Math.Rect.makeWorld(k, k->Context.vec2World(newMinX, newMinY), newWidth, newHeight)
}

let destroy = (pokemon: Pokemon.t, thundershock: t) => {
  thundershock.timerRef->Kaplay.TimerController.cancel

  k->Context.wait(5. * intervalSeconds, () => {
    // Remove the shader from the Pokemon
    pokemon->Pokemon.unuse("shader")

    // Allow the Pokemon to move again
    pokemon.mobility = CanMove
    // Destroy the Thundershock game object
    thundershock->destroy
  })

  k->Context.wait(coolDown, () => {
    // Allow the Pokemon to attack again
    pokemon.attackStatus = CanAttack
  })
}

let nextPartOfBolt = (
  pokemon: Pokemon.t,
  otherPokemon: array<Pokemon.t>,
  direction: Vec2.World.t,
  thundershock: t,
  (),
) => {
  // Propose the next point in world coordinates
  let candidate: Vec2.World.t = {
    let pkmnWorldPos = pokemon->Pokemon.worldPos
    // We use the last point.y + direction.y as the starting point for the next part of the bolt
    let lastPoint = switch thundershock.points->Array.last {
    | Some(point) => point
    | None => pkmnWorldPos
    }

    // We determine the deviation in the x direction, which is a random value between -deviationOffset and deviationOffset
    // Note that the pokemon is anchored in the center.
    let deviationX = k->Context.randf(-1. * deviationOffset, deviationOffset)
    k->Context.vec2World(pkmnWorldPos.x + deviationX, lastPoint.y + direction.y)
  }

  let validCandidate = Math.Rect.containsWorld(Wall.worldRect, candidate)
  let safeCandidate = validCandidate
    ? candidate
    : {
        // Cap the last point to the game bounds edge, then stop
        k->Context.vec2World(
          k->Context.clampFloat(candidate.x, 0., k->Context.width),
          k->Context.clampFloat(candidate.y, 0., k->Context.height),
        )
      }

  thundershock.points->Array.push(safeCandidate)
  thundershock.worldRect = expandRectWithPoint(thundershock.worldRect, safeCandidate)

  if !validCandidate {
    // Schedule own destruction
    destroy(pokemon, thundershock)
  }

  // Check collision with other Pokemon (candidate is already in world coordinates)
  otherPokemon->Array.forEach(otherPokemon => {
    // All points should be check here, not just the last one
    if thundershock.points->Array.some(point => otherPokemon->Pokemon.hasPoint(point)) {
      otherPokemon->Pokemon.setHp(otherPokemon->Pokemon.getHp - 5)
      destroy(pokemon, thundershock)
    }
  })
}

let cast = (pokemon: Pokemon.t) => {
  // Prevent the Pokemon from moving while the Thundershock is active
  pokemon.mobility = CannotMove
  pokemon.attackStatus = Attacking

  // Thundershock is either up or down, so we need to get the direction
  // We used cached vectors with the distance already applied to them
  let direction = pokemon.facing == FacingUp ? up : down

  let otherPokemon =
    k
    ->Context.query({
      include_: ["pokemon"],
    })
    ->Array.filter(p => p->Pokemon.getId != pokemon->Pokemon.getId)

  let thundershock: t = pokemon->Pokemon.addChild(
    [
      k->addPos(0., 0.),
      k->addZ(-1),
      Team.getTagComponent(pokemon.team),
      CustomComponent.make({
        id: "thundershock",
        draw,
        drawInspect,
      }),
      ...addAttackWithTag(@this (thundershock: t) => thundershock.worldRect),
    ],
  )

  thundershock->use(
    initialState({
      points: [pokemon->Pokemon.worldPos],
      worldRect: Kaplay.Math.Rect.makeWorld(k, pokemon->Pokemon.worldPos, 0., 0.),
      timerRef: k->Context.loopWithController(
        intervalSeconds,
        nextPartOfBolt(pokemon, otherPokemon, direction, thundershock, ...),
      ),
    }),
  )

  pokemon->Pokemon.use(
    addShader(k, "glow", ~uniform=() =>
      {
        "u_time": k->Context.time,
        "u_resolution": k->Context.vec2World(pokemon->Pokemon.getWidth, pokemon->Pokemon.getHeight),
        "u_thickness": 0.7,
        "u_color": lighting,
        "u_intensity": 0.66,
        "u_pulse_speed": 5.0,
      }
    ),
  )
}
