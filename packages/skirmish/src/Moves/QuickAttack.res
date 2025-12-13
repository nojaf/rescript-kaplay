open Kaplay

let shaderName = "outline2px"

@module("../../shaders/outline2px.frag?raw")
external outline2pxSource: string = "default"

let load = (k: Context.t) => {
  k->Context.loadShader(shaderName, ~frag=outline2pxSource)
}

let distance = 30.
let duration = 4.

let cast = (k: Context.t, pokemon: Pokemon.t) => {
  Console.log("QuickAttack cast")
  pokemon.attackStatus = Attacking
  pokemon.mobility = CannotMove

  let pokemonWorldPos = pokemon->Pokemon.worldPos
  let startY = pokemonWorldPos->Vec2.World.y
  let endY = startY - distance

  // thought: add attack comp to the pokemon itself so it can be queried for attacks
  // Use a rect that captures its current direction

  let collisionCtrl = ref(KEventController.empty)
  let tweenCtrl = ref(TweenController.empty)

  let endAttack = () => {
    collisionCtrl.contents->KEventController.cancel
    tweenCtrl.contents->TweenController.cancel

    k->Context.wait(0.4, () => {
      pokemon.attackStatus = CanAttack
    })
    pokemon.mobility = CanMove
    pokemon->Pokemon.unuse("shader")
  }

  collisionCtrl :=
    pokemon->Pokemon.onCollideWithController(Team.opponent, (other: Pokemon.t, _) => {
      Console.log("Collided with opponent")
      other->Pokemon.setHp(other->Pokemon.getHp - 3)
      endAttack()
    })

  pokemon->Pokemon.use(
    Pokemon.addShader(k, shaderName, ~uniform=() =>
      {
        "u_resolution": k->Context.vec2World(pokemon->Pokemon.getWidth, pokemon->Pokemon.getHeight),
        "u_color": k->Color.fromHex("#f0f9ff"),
      }
    ),
  )

  pokemon->Pokemon.use(
    Attack.Unit.addAttack(@this _ => {
      let pokemonWorldPos =
        pokemon->Pokemon.worldPos->Vec2.World.addWithXY(-pokemon.halfSize, -pokemon.halfSize)
      let rect = Kaplay.Math.Rect.makeWorld(k, pokemonWorldPos, pokemon->Pokemon.getWidth, 100.)
      rect
    }),
  )

  if k.debug.inspect {
    ()
  }

  pokemon->Pokemon.addTag(Attack.tag)

  // Start attack animation!
  tweenCtrl :=
    k->Context.tweenWithController(
      ~from=startY,
      ~to_=endY,
      ~duration,
      ~setValue=value => {
        pokemon->Pokemon.setWorldPos(k->Context.vec2World(pokemonWorldPos->Vec2.World.x, value))
      },
      ~easeFunc=k.easings.easeOutElastic,
    )

  tweenCtrl.contents->TweenController.onEnd(endAttack)
}
