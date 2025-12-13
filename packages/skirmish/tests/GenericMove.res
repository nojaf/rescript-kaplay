open Kaplay

type t

include GameObjRaw.Comp({type t = t})
include Pos.Comp({type t = t})
include Rect.Comp({type t = t})
include Attack.Comp({type t = t})
include Anchor.Comp({type t = t})
include Color.Comp({type t = t})

let tag = "generic-move"

let getCorner = (attack: t, k: Context.t) => {
  let pkmn =
    k
    ->Context.query({
      include_: [Team.opponent],
    })
    ->Array.get(0)

  switch pkmn {
  | None => None
  | Some(pkmn) => {
      let pkmnPos = pkmn->worldPos
      let closestCorner = getClosestCorner(attack, k, ~pokemonPosition=pkmnPos)
      Some(attack->fromWorld(closestCorner))
    }
  }
}

let make = (k: Context.t, ~x, ~y, ~size: float, team: Team.t): t => {
  let gameObj = k->Context.add(
    [
      Context.tag(tag),
      addPos(k, x, y),
      addAnchorCenter(k),
      Team.getTagComponent(team),
      ...addAttackWithTag(@this (gameObj: t) => {
        let halfSize = size / 2.
        let worldPos = gameObj->worldPos
        Kaplay.Math.Rect.makeWorld(
          k,
          Context.vec2World(k, worldPos.x - halfSize, worldPos.y - halfSize),
          size,
          size,
        )
      }),
      CustomComponent.make({
        id: "generic-move",
        draw: @this
        gameObj => {
          let color = team == Player ? k->Color.fromHex("#00bcff") : k->Color.fromHex("#ff2056")
          Context.drawRect(
            k,
            {
              color,
              pos: k->Context.vec2Local(-size / 2., -size / 2.),
              width: size,
              height: size,
            },
          )

          switch getCorner(gameObj, k) {
          | None => ()
          | Some(corner) => Context.drawCircle(k, {color: k->Color.yellow, pos: corner, radius: 3.})
          }
        },
      }),
    ],
  )

  k->Context.onClick(() => {
    let mousePos = k->Context.mousePos
    let worldPos = k->Context.toWorld(mousePos)
    gameObj->setWorldPos(worldPos)
  })

  gameObj
}
