open Kaplay
open GameContext

type t = {points: array<Vec2.t>}

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

let lighting = k->Color.fromHex("#fef9c2")
let lighting2 = k->Color.fromHex("#fff085")

let draw =
  @this
  (t: t) => {
    k->Context.drawLines({
      pts: t.points,
      width: 2.,
      color: lighting,
      cap: Square,
    })
  }

let worldRect = Kaplay.Math.Rect.make(k, k->Context.vec2Zero, k->Context.width, k->Context.height)

// Add a new point at a fixed interval using a timer loop
let intervalSeconds = 0.050
let deviationOffset = 7.
let distance = 20.

let cast = (pokemon: Pokemon.t) => {
  let direction = pokemon.direction->Vec2.scaleWith(distance)
  let isYAxis = direction.x == 0.
  let thundershock: t = pokemon->Pokemon.addChild([
    Obj.magic({points: [k->Context.vec2Zero]}),
    k->addPos(0., 0.),
    k->addZ(-1),
    CustomComponent.make({
      id: "thundershock",
      draw,
    }),
  ])

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
        "u_resolution": k->Context.vec2(pokemon->Pokemon.getWidth, pokemon->Pokemon.getHeight),
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
        // Propose the next point (from origin), avoiding accumulated lateral drift
        let candidate = {
          let lastPoint = switch thundershock.points->Array.last {
          | Some(point) => point
          | None => k->Context.vec2Zero
          }

          let deviation = k->Context.randf(-1. * deviationOffset, deviationOffset)
          if isYAxis {
            k->Context.vec2(deviation, lastPoint.y + direction.y)
          } else {
            k->Context.vec2(lastPoint.x + direction.x, deviation)
          }
        }

        let candidateInWorldRect = thundershock->worldPos->Vec2.add(candidate)
        if !Kaplay.Math.Rect.contains(worldRect, candidateInWorldRect) {
          // Cap the last point to the game bounds edge, then stop
          let cap = {
            let v = candidateInWorldRect
            v.x = k->Context.clampFloat(v.x, 0., k->Context.width)
            v.y = k->Context.clampFloat(v.y, 0., k->Context.height)
            v
          }
          let cappedLocal = cap->Vec2.sub(thundershock->worldPos)
          thundershock.points->Array.push(cappedLocal)

          // Remove timer
          switch timerRef.contents {
          | None => ()
          | Some(t) => t->Kaplay.TimerController.cancel
          }

          // Schedule own destruction
          k->Context.wait(5. * intervalSeconds, () => {
            pokemon->Pokemon.unuse("shader")
            thundershock->destroy
          })
        } else {
          thundershock.points->Array.push(candidate)
        }

        // Check collision with other Pokemon
        otherPokemon->Array.forEach(otherPokemon => {
          if otherPokemon->Pokemon.hasPoint(candidateInWorldRect) {
            otherPokemon->Pokemon.setHp(otherPokemon->Pokemon.getHp - 5)
          }
        })
      }),
    )
}

let load = (): unit => {
  k->Context.loadShader("glow", ~frag=glowSource)
  k->Context.loadShader("outline2px", ~frag=outline2pxSource)
  k->Context.loadShader("darken", ~frag=darkenSource)

  k->Context.on(~event=(Moves.Thundershock :> string), ~tag=Pokemon.tag, (
    pokemon: Pokemon.t,
    _,
  ) => {
    cast(pokemon)
  })
}
