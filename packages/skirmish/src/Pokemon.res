open Kaplay

@unboxed
type team = | @as(true) Player | @as(false) Opponent

@unboxed
type facing = | @as(true) FacingUp | @as(false) FacingDown

@unboxed
type mobility = | @as(true) CanMove | @as(false) CannotMove

@unboxed
type attackStatus = | @as(true) CanAttack | @as(false) Attacking

type t = {
  mutable direction: Vec2.Unit.t,
  mutable facing: facing,
  mutable mobility: mobility,
  mutable attackStatus: attackStatus,
  level: int,
  pokemonId: int,
  team: team,
}

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

let make = (k: Context.t, ~pokemonId: int, ~level: int, team: team): t => {
  let gameObj: t = k->Context.add(
    [
      // initialState
      ...team == Player
        ? [
            internalState({
              direction: k->Context.vec2Up,
              level,
              pokemonId,
              team,
              facing: FacingUp,
              mobility: CanMove,
              attackStatus: CanAttack,
            }),
            k->addPos(k->Context.center->Vec2.World.x, k->Context.height * 0.8),
            k->addSprite(backSpriteName(pokemonId)),
          ]
        : [
            internalState({
              direction: k->Context.vec2Down,
              level,
              pokemonId,
              team,
              facing: FacingDown,
              mobility: CanMove,
              attackStatus: CanAttack,
            }),
            k->addPos(k->Context.center->Vec2.World.x, k->Context.height * 0.2),
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

  gameObj
}
