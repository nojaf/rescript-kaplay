open Kaplay

type t

include GameObjRaw.Comp({type t = t})
include Pos.Comp({type t = t})
include Rect.Comp({type t = t})
include Attack.Comp({type t = t})
include Anchor.Comp({type t = t})
include Color.Comp({type t = t})

let make = (k: Context.t, ~x, ~y, ~size, team: Team.t): t => {
  let gameObj =
    k->Context.add([
      addPos(k, x, y),
      addRect(k, size, size),
      addAnchorCenter(k),
      addColor(k, k->Color.fromHex(team == Player ? "#00bcff" : "#ff2056")),
      Attack.tagComponent,
      Team.getTagComponent(team),
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

  let speed = 100.

  k->Context.onKeyDown(key => {
    switch key {
    | Up => gameObj->move(k->Context.vec2World(0., -speed))
    | Down => gameObj->move(k->Context.vec2World(0., speed))
    | Left => gameObj->move(k->Context.vec2World(-speed, 0.))
    | Right => gameObj->move(k->Context.vec2World(speed, 0.))
    | _ => ()
    }
  })

  k->Context.onClick(() => {
    let mousePos = k->Context.mousePos
    let worldPos = k->Context.toWorld(mousePos)
    gameObj->setWorldPos(worldPos)
  })

  gameObj
}
