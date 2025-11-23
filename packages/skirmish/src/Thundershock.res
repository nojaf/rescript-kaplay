open Kaplay
open GameContext

type t = {points: array<Vec2.t>}

include Pos.Comp({type t = t})
include Anchor.Comp({type t = t})
include GameObjRaw.Comp({type t = t})
include Z.Comp({type t = t})

let lighting = k->Color.fromHex("#ffdf20")
let lighting2 = k->Color.fromHex("#fee685")

let draw =
  @this
  (t: t) => {
    for i in 0 to t.points->Array.length - 1 {
      switch (t.points[i], t.points[i + 1]) {
      | (Some(p1), Some(p2)) =>
        k->Context.drawLine({
          p1,
          p2,
          width: 2.,
          color: i % 3 == 0 ? lighting : lighting2,
        })
      | _ => ()
      }
    }
  }

let worldRect = Kaplay.Math.Rect.make(k, k->Context.vec2Zero, k->Context.width, k->Context.height)

// Add a new point at a fixed interval using a timer loop
let intervalSeconds = 0.050
let deviationOffset = 7.
let distance = 20.

let make = (addToParent: array<Types.comp> => t, origin: Vec2.t, direction: Vec2.t) => {
  let direction = direction->Vec2.scaleWith(distance)
  Console.log4("Origin: ", origin, "Direction: ", direction)
  let gameObj: t = addToParent([
    Obj.magic({points: [k->Context.vec2Zero]}),
    k->addPos(0., 0.),
    k->addZ(-1),
    CustomComponent.make({
      id: "thundershock",
      draw,
    }),
  ])

  let timerRef: ref<option<Kaplay.TimerController.t>> = ref(None)
  timerRef :=
    Some(
      k->Context.loop(intervalSeconds, () => {
        // Propose the next point (from origin), avoiding accumulated lateral drift
        let candidate = {
          let lastPoint = switch gameObj.points->Array.last {
          | Some(point) => point
          | None => k->Context.vec2Zero
          }

          let deviation = k->Context.randf(-1. * deviationOffset, deviationOffset)
          k->Context.vec2(deviation, lastPoint.y + direction.y)
        }

        let candidateInWorldRect = gameObj->worldPos->Vec2.add(candidate)
        if !Kaplay.Math.Rect.contains(worldRect, candidateInWorldRect) {
          // Cap the last point to the game bounds edge, then stop
          let cap = {
            let v = candidateInWorldRect
            v.x = k->Context.clampFloat(v.x, 0., k->Context.width)
            v.y = k->Context.clampFloat(v.y, 0., k->Context.height)
            v
          }
          let cappedLocal = cap->Vec2.sub(gameObj->worldPos)
          gameObj.points->Array.push(cappedLocal)
          switch timerRef.contents {
          | None => ()
          | Some(t) => t->Kaplay.TimerController.cancel
          }
        } else {
          gameObj.points->Array.push(candidate)
        }
      }),
    )
}
