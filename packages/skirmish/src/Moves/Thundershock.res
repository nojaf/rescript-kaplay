open Kaplay
open GameContext

type t = {points: array<Vec2.World.t>}

include Pos.Comp({type t = t})
include Anchor.Comp({type t = t})
include GameObjRaw.Comp({type t = t})
include Z.Comp({type t = t})
include Shader.Comp({type t = t})

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
let lighting2 = k->Color.fromHex("#fff085")

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

// TODO: extract and figure out proper world coordinates rect (keeping status bars in mind)
let worldRect = Kaplay.Math.Rect.make(
  k,
  k->Context.vec2ZeroWorld,
  k->Context.width,
  k->Context.height,
)

// Add a new point at a fixed interval using a timer loop
let intervalSeconds = 0.050
let deviationOffset = 7.
let distance = 20.
// Scale unit direction vectors to create world coordinate offsets
let up: Vec2.World.t = k->Context.vec2Up->Vec2.Unit.asWorld->Vec2.World.scaleWith(distance)
let down: Vec2.World.t = k->Context.vec2Down->Vec2.Unit.asWorld->Vec2.World.scaleWith(distance)

external initialState: t => Types.comp = "%identity"

let cast = (pokemon: Pokemon.t) => {
  // Prevent the Pokemon from moving while the Thundershock is active
  pokemon.mobility = CannotMove
  pokemon.attackStatus = Attacking

  // Thundershock is either up or down, so we need to get the direction
  // We used cached vectors with the distance already applied to them
  let direction = pokemon.facing == FacingUp ? up : down

  let thundershock: t = pokemon->Pokemon.addChild([
    initialState({points: []}),
    k->addPos(0., 0.),
    k->addZ(-1),
    CustomComponent.make({
      id: "thundershock",
      draw,
    }),
  ])

  // Initialize with Pokemon's world position as first point
  let initialWorldPos = pokemon->Pokemon.worldPos
  thundershock.points->Array.push(initialWorldPos)

  let otherPokemon =
    k
    ->Context.query({
      include_: ["pokemon"],
    })
    ->Array.filter(p => p->Pokemon.getId != pokemon->Pokemon.getId)

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

  let timerRef: ref<option<Kaplay.TimerController.t>> = ref(None)
  timerRef :=
    Some(
      k->Context.loopWithController(intervalSeconds, () => {
        // Propose the next point in world coordinates
        let candidate: Vec2.World.t = {
          let lastPoint = switch thundershock.points->Array.last {
          | Some(point) => point
          | None => pokemon->Pokemon.worldPos
          }

          let deviation = k->Context.randf(-1. * deviationOffset, deviationOffset)
          lastPoint->Vec2.World.addWithXY(deviation, direction.y)
        }

        // Check bounds in world coordinates
        if !Kaplay.Math.Rect.contains(worldRect, candidate) {
          // Cap the last point to the game bounds edge, then stop
          let cap: Vec2.World.t =
            k->Context.vec2World(
              k->Context.clampFloat(candidate.x, 0., k->Context.width),
              k->Context.clampFloat(candidate.y, 0., k->Context.height),
            )
          thundershock.points->Array.push(cap)

          // Remove timer
          switch timerRef.contents {
          | None => ()
          | Some(t) => t->Kaplay.TimerController.cancel
          }

          // Schedule own destruction
          k->Context.wait(5. * intervalSeconds, () => {
            // Remove the shader from the Pokemon
            pokemon->Pokemon.unuse("shader")

            // Allow the Pokemon to move again
            pokemon.mobility = CanMove
            pokemon.attackStatus = CanAttack
            // Destroy the Thundershock game object
            thundershock->destroy
          })
        } else {
          thundershock.points->Array.push(candidate)
        }

        // Check collision with other Pokemon (candidate is already in world coordinates)
        otherPokemon->Array.forEach(otherPokemon => {
          // TODO: all points should be check here, not just the last one

          if otherPokemon->Pokemon.hasPoint(candidate) {
            otherPokemon->Pokemon.setHp(otherPokemon->Pokemon.getHp - 1)
          }
        })
      }),
    )
}
