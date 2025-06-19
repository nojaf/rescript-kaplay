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
        addColor(k, k->Color.fromHex(color)),
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
          text->setColor(k->Color.fromHex(hoverColor))
        })
        text->onHoverEnd(() => {
          text->setColor(k->Color.fromHex(color))
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
  let centerX = k->Context.width / 2.
  let topY = k->Context.height / 4.
  let space = 75.
  let _ = Text.make(k, title, ~x=centerX, ~y=topY, Text.Center, ~size=60., ~color?)
  menuItems->Array.forEachWithIndex((menuItem, index) => {
    let y = topY + (index :> float) * space + 100.
    let _ = Text.make(
      k,
      menuItem.label,
      ~x=centerX,
      ~y,
      Text.Center,
      ~size=24.,
      ~color?,
      ~hoverColor=?menuItem.action->Option.flatMap(_ => hoverColor),
      ~action=?menuItem.action,
    )
  })
}
