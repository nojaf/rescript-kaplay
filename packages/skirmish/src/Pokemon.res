open Kaplay
open GameContext

type team = Player | Opponent

type t = {mutable direction: Vec2.t, level: int, pokemonId: int, team: team}

include GameObjRaw.Comp({type t = t})
include Pos.Comp({type t = t})
include Sprite.Comp({type t = t})
include Area.Comp({type t = t})
include Health.Comp({type t = t})
include Anchor.Comp({type t = t})
include Shader.Comp({type t = t})
include Opacity.Comp({type t = t})
include Animate.Comp({type t = t})

let tag = "pokemon"

/* Helpers to consistently compose sprite names and URLs from an id */
let frontSpriteName = (id: int) => "pokemon-" ++ Int.toString(id) ++ "-front"
let backSpriteName = (id: int) => "pokemon-" ++ Int.toString(id) ++ "-back"

let frontSpriteUrl = (id: int) => `/sprites/${Int.toString(id)}-front.png`
let backSpriteUrl = (id: int) => `/sprites/${Int.toString(id)}-back.png`

/* Load both front and back sprites for the given pokemon id */
let load = (id: int): unit => {
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

let hurtHandler = (pokemon: t, deltaHp: int) => {
  Console.log2("I hurt myself today", deltaHp)

  // Stop any existing opacity animation and reset the internal clock
  pokemon->unanimate("opacity")
  pokemon->getAnimation->(animation => animation.seek(0.))
}

let make = (~pokemonId: int, ~level: int, team: team): t => {
  let gameObj: t = k->Context.add(
    [
      // initialState
      ...team == Player
        ? [
            internalState({direction: k->Context.vec2Up, level, pokemonId, team}),
            k->addPos(k->Context.center->Vec2.x, k->Context.height * 0.8),
            k->addSprite(backSpriteName(pokemonId)),
          ]
        : [
            internalState({direction: k->Context.vec2Down, level, pokemonId, team}),
            k->addPos(k->Context.center->Vec2.x, k->Context.height * 0.2),
            k->addSprite(frontSpriteName(pokemonId)),
          ],
      k->addArea,
      k->addHealth(20, ~maxHP=20),
      k->addAnchorCenter,
      k->addOpacity(1.),
      k->addAnimate,
      Context.tag(tag),
    ],
  )

  gameObj->onHurt((deltaHp: int) => {
    Console.log2("I hurt myself today", deltaHp)

    // Stop any existing opacity animation and reset the internal clock
    gameObj->unanimate("opacity")
    gameObj->getAnimation->(animation => animation.seek(0.))
  })

  gameObj
}
