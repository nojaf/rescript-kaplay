open Kaplay
open GameContext

type t = {
  mutable healthPercentage: float,
  mutable tweenControllerRef?: TweenController.t,
}

external initialState: t => Types.comp = "%identity"

include Pos.Comp({type t = t})

let good = k->Color.fromHex("#00bc7d") // green
let middle = k->Color.fromHex("#ffdf20") // yellow
let bad = k->Color.fromHex("#e7000b") // red

let getHealthColor = (healthPercent: float): Color.t => {
  switch healthPercent {
  | hp if hp >= 70. => {
      // Interpolate between good (100%) and middle (70%)
      // At 100%: t=0 (pure good), at 70%: t=1 (pure middle)
      let t = (100. -. hp) /. 30.
      good->Color.lerp(middle, t)
    }
  | hp if hp >= 40. => {
      // Interpolate between middle (70%) and bad (40%)
      // At 70%: t=0 (pure middle), at 40%: t=1 (pure bad)
      let t = (70. -. hp) /. 30.
      middle->Color.lerp(bad, t)
    }
  | _ => // Below 40%, use bad color
    bad
  }
}

let setHealth = (healthbar: t, targetPercent: float) => {
  // Cancel any existing tween
  switch healthbar.tweenControllerRef {
  | None => ()
  | Some(controller) => controller->TweenController.cancel
  }

  // Start tween from current animated value to target
  let controller = k->Context.tweenWithController(
    ~from=healthbar.healthPercentage,
    ~to_=targetPercent,
    ~duration=0.33,
    ~setValue=value => {
      healthbar.healthPercentage = value
    },
    ~easeFunc=k.easings.easeOutSine,
  )

  // Clear the ref when tween completes
  controller->TweenController.onEnd(() => {
    healthbar.tweenControllerRef = None
  })

  healthbar.tweenControllerRef = Some(controller)
}

let draw =
  @this
  (healthbar: t) => {
    // Lines
    k->Context.drawLines({
      pts: [
        //
        k->Context.vec2Zero,
        k->Context.vec2(0., 40.),
        k->Context.vec2(k->Context.width / 2., 40.),
      ],
      color: k->Color.black,
      width: 2.,
    })

    // Pokemon name
    k->Context.drawText({
      pos: k->Context.vec2(5., 0.),
      text: "Charmander"->String.toUpperCase,
      letterSpacing: 0.5,
      size: 15.,
      color: k->Color.black,
      font: Context.makeDrawTextFontInfoFromString("system-ui"),
    })

    // HP:
    k->Context.drawText({
      pos: k->Context.vec2(5., 26.),
      text: "HP:",
      size: 7.,
      color: k->Color.black,
    })

    //Healthbar background
    k->Context.drawRect({
      pos: k->Context.vec2(20., 26.),
      width: 100.,
      height: 6.,
      radius: [3., 3., 3., 3.],
      color: k->Color.fromHex("#e5e7eb"),
      outline: {
        width: 1.,
        color: k->Color.black,
      },
    })

    // Actual healthbar - use animated value
    let animatedPercent = healthbar.healthPercentage
    let healthColor = getHealthColor(animatedPercent)
    let healthbarWidth = healthbar.healthPercentage

    k->Context.drawRect({
      pos: k->Context.vec2(20., 26.),
      width: healthbarWidth,
      height: 5.,
      radius: [3., 0., 0., 3.],
      color: healthColor,
    })
  }

let make = (pokemon: Pokemon.t) => {
  let healthbar: t = k->Context.add([
    initialState({
      healthPercentage: pokemon->Pokemon.getHealthPercentage,
    }),
    CustomComponent.make({id: "healthbar", draw}),
    addPos(k, 10., 10.),
  ])

  pokemon
  ->Pokemon.onHurt(_deltaHP => {
    let newHealthPercent = pokemon->Pokemon.getHealthPercentage
    setHealth(healthbar, newHealthPercent)
  })
  ->ignore

  healthbar
}
