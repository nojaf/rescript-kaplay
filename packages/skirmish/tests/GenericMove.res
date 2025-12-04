open Kaplay

type t

include GameObjRaw.Comp({type t = t})
include Pos.Comp({type t = t})
include Rect.Comp({type t = t})
include Attack.Comp({type t = t})
include Anchor.Comp({type t = t})
include Color.Comp({type t = t})

let getCorner = (k: Context.t, ~pos: Vec2.World.t, ~size: float) => {
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
      let isLeft = pkmnPos.x < pos.x
      let isTop = pkmnPos.y < pos.y
      switch (isLeft, isTop) {
      | (true, true) => Some(k->Context.vec2Local(-size / 2., -size / 2.))
      | (true, false) => Some(k->Context.vec2Local(-size / 2., size / 2.))
      | (false, true) => Some(k->Context.vec2Local(size / 2., -size / 2.))
      | (false, false) => Some(k->Context.vec2Local(size / 2., size / 2.))
      }
    }
  }
}

let make = (k: Context.t, ~x, ~y, ~size: float, team: Team.t): t => {
  let gameObj = k->Context.add([
    addPos(k, x, y),
    addAnchorCenter(k),
    Attack.tagComponent,
    Team.getTagComponent(team),
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

        let worldPos = gameObj->worldPos
        switch getCorner(k, ~pos=worldPos, ~size) {
        | None => ()
        | Some(corner) => Context.drawCircle(k, {color: k->Color.yellow, pos: corner, radius: 3.})
        }
      },
    }),
  ])

  gameObj->use(
    addAttack(() => {
      let halfSize = size / 2.
      let worldPos = gameObj->worldPos
      Kaplay.Math.Rect.makeWorld(
        k,
        Context.vec2World(k, worldPos.x - halfSize, worldPos.y - halfSize),
        size,
        size,
      )
    }),
  )

  k->Context.onClick(() => {
    let mousePos = k->Context.mousePos
    let worldPos = k->Context.toWorld(mousePos)
    gameObj->setWorldPos(worldPos)
  })

  gameObj
}
