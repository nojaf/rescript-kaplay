open Kaplay
open GameContext

module Text = {
  type t

  include Kaplay.Text.Comp({type t = t})
  include Color.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Anchor.Comp({type t = t})

  let make = (text: string) => {
    [
      //
      addText(k, text, ~options={size: 24.}),
      addColor(k, k->Context.colorFromHex("#000000")),
      addPos(k, 150., 18.),
      addAnchorCenter(k),
    ]
  }
}

module Button = {
  type t = {scene: string}

  include GameObjRaw.Comp({type t = t})
  include Outline.Comp({type t = t})
  include Rect.Comp({type t = t})
  include Color.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Area.Comp({type t = t})

  external addState: t => Types.comp = "%identity"

  let make = (text: string, scene, y: float): t => {
    let textComp = Text.make(text)
    let button: t = k->Context.add([
      //
      addPos(k, (k->Context.center).x - 150., y),
      addRect(k, 300., 36.),
      addColor(k, k->Context.colorFromHex("#f1f5f9")),
      addOutline(k, ~color=k->Context.colorFromHex("#000000"), ~width=2),
      addState({scene: scene}),
      addArea(k),
    ])

    button->add(textComp)->ignore

    button
  }
}

let title = k->Context.add(Text.make("Rescript & KAPLAY examples"))
title->Text.setPos(k->Context.vec2((k->Context.center).x, 30.))

k->Context.scene("squirtle", Squirtle.scene)
k->Context.scene("middle-earth", MiddleEarth.scene)
k->Context.scene("path-finding", PathFinding.scene)
k->Context.scene("sentry", SentrySample.scene)
k->Context.scene("tower", Tower.scene)

let buttons = [
  Button.make("squirtle", "squirtle", 60.),
  Button.make("middle-earth", "middle-earth", 120.),
  Button.make("path-finding", "path-finding", 180.),
  Button.make("sentry", "sentry", 240.),
  Button.make("tower", "tower", 300.),
]

buttons->Array.forEach(button => {
  button
  ->Button.onClick(() => {
    k->Context.go(button.scene)
  })
  ->ignore
})
