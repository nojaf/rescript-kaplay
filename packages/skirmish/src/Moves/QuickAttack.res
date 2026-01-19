open Kaplay

let shaderName = "outline2px"

@module("../../shaders/outline2px.frag?raw")
external outline2pxSource: string = "default"

let load = (k: Context.t) => {
  k->Context.loadShader(shaderName, ~frag=outline2pxSource)
}

let distance = 30.
let duration = 0.4
let cooldown = 0.4

let cast = (k: Context.t, pokemon: Pokemon.t) => {
  Console.log("QuickAttack cast")
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

    k->Context.wait(cooldown, () => {
      pokemon->Pokemon.finishAttack
    })
    pokemon.mobility = CanMove
    pokemon->Pokemon.unuse("shader")
  }

  collisionCtrl :=
    pokemon->Pokemon.onCollideWithController(Team.opponent, (other: Pokemon.t, _) => {
      if other->Pokemon.is(Pokemon.tag) {
        Console.log("Collided with opponent")
        other->Pokemon.setHp(other->Pokemon.getHp - 3)

        // Calculate bounce direction (from other to pokemon)
        let pokemonPos = pokemon->Pokemon.worldPos
        let otherPos = other->Pokemon.worldPos
        let bounceDirection = pokemonPos->Vec2.World.sub(otherPos)->Vec2.World.unit

        // Apply bounce force to both pokemon
        let bounceImpulse = 90. // velocity in pixels/sec
        pokemon->Pokemon.applyImpulse(bounceDirection->Vec2.World.scaleWith(bounceImpulse))
        other->Pokemon.applyImpulse(bounceDirection->Vec2.World.scaleWith(-.bounceImpulse))

        k->Context.wait(0.15, () => {
          pokemon->Pokemon.setVel(k->Context.vec2ZeroWorld)
          other->Pokemon.setVel(k->Context.vec2ZeroWorld)
        })

        endAttack()
      }
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

let move: PkmnMove.t = {
  id: 3,
  name: "Quick Attack",
  maxPP: 30,
  baseDamage: 40,
  coolDownDuration: cooldown,
  cast: (k, pkmn) => cast(k, pkmn->Pokemon.fromAbstractPkmn),
  addRulesForAI: (_, _, _, _) => (),
}
