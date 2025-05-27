open Kaplay
open GameContext

module Bird = {
  type t

  include Pos.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Body.Comp({type t = t})
  include Color.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Area.Comp({type t = t})

  let make = () => {
    k->Context.add([
      k->addPosFromVec2(k->Context.center),
      k->addSprite("pidgeotto", ~options={flipX: true}),
      k->addBody,
      k->addColor(k->Context.colorFromHex("#ffb86a")),
      k->addAnchorCenter,
      k->addArea,
    ])
  }
}

let scene = () => {
  k->Context.loadSprite("pidgeotto", "sprites/pidgeotto-rb.png")
  k->Context.setBackground(k->Context.colorFromHex("#cefafe"))

  k->Context.setGravity(9.8)

  let bird = Bird.make()
}

let x: int = "err"
