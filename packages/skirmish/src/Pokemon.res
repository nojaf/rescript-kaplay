open Kaplay

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
  team: Team.t,
  /** Half size of the pokemon in world units */
  halfSize: float,
  /** Squared distance between the pokemon and what we consider its personal space
      This is used to determine how close a potential attack is to the pokemon's personal space.
   */
  squaredPersonalSpace: float,
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
include Body.Comp({type t = t})

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

let moveLeft = (k: Context.t, pokemon: t) => {
  pokemon->move(k->Context.vec2World(-100., 0.))
}

let moveRight = (k: Context.t, pokemon: t) => {
  pokemon->move(k->Context.vec2World(100., 0.))
}

let make = (k: Context.t, ~pokemonId: int, ~level: int, team: Team.t): t => {
  let (spriteName, direction, posY) = if team == Player {
    (backSpriteName(pokemonId), k->Context.vec2Up, k->Context.height * 0.75)
  } else {
    (frontSpriteName(pokemonId), k->Context.vec2Down, k->Context.height * 0.25)
  }
  let (halfSize, squaredPersonalSpace) = switch Context.getSprite(k, spriteName).data {
  | Null.Null => (0., 0.)
  | Null.Value(sprite) => {
      let halfSize = sprite->SpriteData.width / 2.
      // Twice the radius of a circle around the sprite.
      let squaredPersonalSpace = halfSize * halfSize * halfSize
      (halfSize, squaredPersonalSpace)
    }
  }

  let gameObj: t = k->Context.add([
    // initialState
    internalState({
      direction,
      level,
      pokemonId,
      team,
      facing: FacingUp,
      mobility: CanMove,
      attackStatus: CanAttack,
      halfSize,
      squaredPersonalSpace,
    }),
    k->addPos(k->Context.center->Vec2.World.x, posY),
    k->addSprite(frontSpriteName(pokemonId)),
    team == Player ? Team.playerTagComponent : Team.opponentTagComponent,
    k->addArea,
    k->addBody,
    k->addHealth(20, ~maxHP=20),
    k->addAnchorCenter,
    k->addOpacity(1.),
    k->addAnimate,
    Context.tag(tag),
    CustomComponent.make({
      id: "pokemon",
      drawInspect: @this
      (gameObj: t) => {
        let radius = Stdlib_Math.sqrt(gameObj.squaredPersonalSpace)
        k->Context.drawCircle({
          radius,
          opacity: 0.1,
          outline: {
            color: k->Color.magenta,
            width: 2.,
          },
        })
      },
    }),
  ])

  gameObj->onHurt((_deltaHp: int) => {
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
