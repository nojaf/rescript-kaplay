open Kaplay
open GameContext

type t = {
  mutable healthPercentage: float,
  mutable tweenControllerRef?: TweenController.t,
  name: string,
  level: int,
  team: Team.t,
}

external initialState: t => Types.comp = "%identity"

include Pos.Comp({type t = t})

let good = k->Color.fromHex("#00bc7d") // green
let middle = k->Color.fromHex("#ffdf20") // yellow
let bad = k->Color.fromHex("#e7000b") // red

let middleUpperLimit = 60.
let middleLowerLimit = 20.

let getHealthColor = (healthPercent: float): Color.t => {
  switch healthPercent {
  | hp if hp >= middleUpperLimit => {
      // Interpolate between good (100%) and middle (70%)
      // At 100%: t=0 (pure good), at 70%: t=1 (pure middle)
      // Range: 100 - 70 = 30 percentage points
      let t = (100. -. hp) /. (100. -. middleUpperLimit)
      good->Color.lerp(middle, t)
    }
  | hp if hp >= middleLowerLimit => {
      // Interpolate between middle (70%) and bad (20%)
      // At 70%: t=0 (pure middle), at 20%: t=1 (pure bad)
      // Range: 70 - 20 = 50 percentage points
      let t = (middleUpperLimit -. hp) /. (middleUpperLimit -. middleLowerLimit)
      middle->Color.lerp(bad, t)
    }
  | _ => // Below 20%, use bad color
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
    let lines =
      healthbar.team == Team.Opponent
        ? [
            k->Context.vec2ZeroLocal,
            k->Context.vec2Local(0., 40.),
            k->Context.vec2Local(k->Context.width / 2., 40.),
          ]
        : [
            k->Context.vec2Local(k->Context.width / 2., 0.),
            k->Context.vec2Local(k->Context.width / 2., 40.),
            k->Context.vec2Local(0., 40.),
          ]

    k->Context.drawLines({
      pts: lines,
      color: k->Color.black,
      width: 2.,
    })

    // Pokemon name
    k->Context.drawText({
      pos: k->Context.vec2Local(5., 0.),
      text: healthbar.name->String.toUpperCase,
      letterSpacing: 0.5,
      size: 10.,
      color: k->Color.black,
      font: PkmnFont.font,
    })

    // Pokemon level
    k->Context.drawText({
      pos: k->Context.vec2Local(70., 12.),
      text: ":L" ++ Int.toString(healthbar.level),
      size: 10.,
      color: k->Color.black,
      font: PkmnFont.font,
    })

    // HP:
    k->Context.drawText({
      pos: k->Context.vec2Local(5., 25.),
      text: "HP:",
      size: 6.,
      color: k->Color.black,
      font: PkmnFont.font,
    })

    //Healthbar background
    k->Context.drawRect({
      pos: k->Context.vec2Local(25., 25.),
      width: 100.,
      height: 5.,
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
      pos: k->Context.vec2Local(25., 25.),
      width: healthbarWidth,
      height: 5.,
      radius: [3., 0., 0., 3.],
      color: healthColor,
    })
  }

// TODO: maybe change the anchor based on player or opponent

let make = (pokemon: Pokemon.t) => {
  let healthbar: t = k->Context.add([
    initialState({
      healthPercentage: pokemon->Pokemon.getHealthPercentage,
      name: MetaData.names->Map.get(pokemon.pokemonId)->Option.getOr("???"),
      level: pokemon.level,
      team: pokemon.team,
    }),
    CustomComponent.make({id: "healthbar", draw}),
    pokemon.team == Team.Opponent
      ? addPos(k, 10., 10.)
      : addPos(k, k->Context.width / 2. - 10., k->Context.height - 50.),
  ])

  pokemon
  ->Pokemon.onHurt(_deltaHP => {
    let newHealthPercent = pokemon->Pokemon.getHealthPercentage
    setHealth(healthbar, newHealthPercent)
  })
  ->ignore

  healthbar
}
