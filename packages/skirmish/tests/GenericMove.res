open Kaplay

type t

include Pos.Comp({type t = t})
include Rect.Comp({type t = t})
include Attack.Comp({type t = t})
include Anchor.Comp({type t = t})
include Color.Comp({type t = t})

let make = (k: Context.t, ~x, ~y, ~size, team: Team.t): t => {
  k->Context.add([
    addPos(k, x, y),
    addRect(k, size, size),
    addAnchorCenter(k),
    addColor(k, k->Color.fromHex(team == Player ? "#00bcff" : "#ff2056")),
    Attack.tagComponent,
    Team.getTagComponent(team),
    addAttack(() => {
      Kaplay.Math.Rect.makeWorld(k, Context.vec2World(k, x, y), size, size)
    }),
  ])
}
