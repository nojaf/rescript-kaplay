open Kaplay
open Kaplay.Context
open GameContext

module Squirtle = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Color.Comp({type t = t})
  include Area.Comp({type t = t})
  include Body.Comp({type t = t})
  include Anchor.Comp({type t = t})

  let make = () => {
    k->Context.add([
      k->addSprite("squirtle"),
      k->addPos(100., 100.),
      k->addAnchorCenter,
      k->addColor(k->colorFromHex("#ADD8E6")),
      k->addArea,
      k->addBody,
    ])
  }
}

module Flareon = {
  type t

  include Sprite.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Color.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Sentry.Comp({type t = t})

  let make = (squirtle: Squirtle.t) => {
    k->Context.add([
      k->addSprite("flareon"),
      k->addPos(400., 400.),
      k->addAnchorCenter,
      k->addColor(k->colorFromHex("#FF746C")),
      k->addSentry(
        [squirtle],
        ~options={
          fieldOfView: 45.,
          direction: k->vec2(0., 0.),
          lineOfSight: true,
          checkFrequency: 0.200,
        },
      ),
    ])
  }
}

module Wall = {
  type t

  include Rect.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Color.Comp({type t = t})
  include Area.Comp({type t = t})
  include Body.Comp({type t = t})
  include Anchor.Comp({type t = t})

  let make = () => {
    k->Context.add([
      k->addRect(20., 700.),
      k->addPos(300., 200.),
      k->addAnchorCenter,
      k->addColor(k->colorFromHex("#D1E2F3")),
      k->addArea,
      k->addBody(~options={isStatic: true}),
    ])
  }
}

module Text = {
  type t

  include Text.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Pos.Comp({type t = t})

  let make = () => {
    k->Context.add([
      //
      k->addText("Move underneath Flareon (red) to be spotted", ~options={size: 20.}),
      k->addPos(k->Context.width - 20., k->Context.height - 20.),
      k->addAnchor(BottomRight),
    ])
  }
}

let scene = () => {
  k->loadSprite("squirtle", `${baseUrl}/sprites/squirtle-rb.png`)
  k->loadSprite("flareon", `${baseUrl}/sprites/flareon-rb.png`)

  let squirtle = Squirtle.make()
  let flareon = Flareon.make(squirtle)

  let _wall = Wall.make()

  Text.make()->ignore

  flareon
  ->Flareon.onObjectsSpotted(spotted => {
    k.debug->Debug.log(`Spotted squirtle: ${spotted->Array.length->Int.toString}`)
  })
  ->ignore

  squirtle
  ->Squirtle.onKeyDown(key => {
    switch key {
    | Left => squirtle->Squirtle.move(k->vec2(-400., 0.))
    | Right => squirtle->Squirtle.move(k->vec2(400., 0.))
    | Up => squirtle->Squirtle.move(k->vec2(0., -400.))
    | Down => squirtle->Squirtle.move(k->vec2(0., 400.))
    | _ => ()
    }
  })
  ->ignore
}
