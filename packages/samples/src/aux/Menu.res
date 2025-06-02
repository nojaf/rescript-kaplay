open Kaplay

module Text = {
  type t

  include Pos.Comp({type t = t})
  include Text.Comp({type t = t})
  include Color.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Area.Comp({type t = t})

  let make = (
    k,
    text: string,
    ~x,
    ~y,
    anchor,
    ~color="#000000",
    ~size=24.,
    ~action: option<unit => unit>=?,
    ~hoverColor: option<string>=?,
  ): t => {
    let text: t =
      k->Context.add([
        addPos(k, x, y),
        addText(k, text, ~options={size: size}),
        addColor(k, k->Context.colorFromHex(color)),
        addAnchor(k, anchor),
        k->addArea,
      ])

    switch action {
    | None => ()
    | Some(action) => text->onClick(action)
    }

    switch hoverColor {
    | None => ()
    | Some(hoverColor) => {
        text->onHover(() => {
          text->setColor(k->Context.colorFromHex(hoverColor))
        })
        text->onHoverEnd(() => {
          text->setColor(k->Context.colorFromHex(color))
        })
      }
    }

    text
  }
}

type menuItem = {
  label: string,
  action?: unit => unit,
}

let make = (k, title, menuItems, ~color=?, ~hoverColor=?) => {
  // Calculate font size with this base
  let baseCanvasHeight = 500.
  let canvasHeight = k->Context.height
  let scaleFactor = canvasHeight / baseCanvasHeight

  let centerX = k->Context.width / 2.
  let topY = k->Context.height / 4.
  let space = 70. * scaleFactor
  let _ = Text.make(k, title, ~x=centerX, ~y=topY, Text.Center, ~size=36. * scaleFactor, ~color?)
  menuItems->Array.forEachWithIndex((menuItem, index) => {
    let y = topY + (index + 1 :> float) * space
    let _ = Text.make(
      k,
      menuItem.label,
      ~x=centerX,
      ~y,
      Text.Center,
      ~size=24. * scaleFactor,
      ~color?,
      ~hoverColor=?menuItem.action->Option.flatMap(_ => hoverColor),
      ~action=?menuItem.action,
    )
  })
}
