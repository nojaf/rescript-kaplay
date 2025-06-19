open Kaplay
open Kaplay.Context

let k = kaplay(
  ~initOptions={
    width: 800,
    height: 400,
    background: "#66CCCC",
    scale,
    crisp: true,
  },
)

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
      k->addColor(k->Color.fromHex("#ADD8E6")),
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
      k->addPos(450., 100.),
      k->addAnchorCenter,
      k->addColor(k->Color.fromHex("#FF746C")),
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

  let make = () => {
    k->Context.add([
      k->addRect(20., 200.),
      k->addPos(250., 0.),
      k->addColor(k->Color.fromHex("#D1E2F3")),
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
      k->addText(
        "Use the arrow keys to move underneath Flareon (red) to be spotted",
        ~options={size: 16.},
      ),
      k->addPos(k->Context.width - 20., k->Context.height - 20.),
      k->addAnchor(BottomRight),
    ])
  }
}

let onLoad = () => {
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

k->loadSprite("squirtle", `${baseUrl}/sprites/squirtle-rb.png`)
k->loadSprite("flareon", `${baseUrl}/sprites/flareon-rb.png`)
k->Context.onLoad(onLoad)
