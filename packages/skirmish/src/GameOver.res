open Kaplay
open GameContext

module GameOverScreen = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Area.Comp({type t = t})
  include Text.Comp({type t = t})

  let make = (k: Context.t, ~teamWhoLost: Team.t) => {
    let (btnWidth, btnHeight) = (180., 50.)
    let btnPos =
      k->Context.vec2Local(k->Context.width / 2. - btnWidth / 2., k->Context.height * 0.66)
    let rect = Kaplay.Math.Rect.makeLocal(k, btnPos, btnWidth, btnHeight)
    let btn = k->Context.add([
      addPosFromVec2(k, k->Context.vec2ZeroLocal),
      addArea(k, ~options={shape: rect->Kaplay.Math.Rect.asShape}),
      CustomComponent.make({
        id: "game-over-screen",
        draw: @this
        _ => {
          // Draw title
          k->Context.drawText({
            text: teamWhoLost == Opponent ? "You win!" : "You lose!",
            color: k->Color.black,
            pos: k->Context.vec2Local(0., k->Context.height / 4.),
            width: k->Context.width,
            size: 32.,
            align: Center,
            font: PkmnFont.font,
          })

          // Draw button

          k->Context.drawRect({
            color: k->Color.fromHex("#fb2c36"),
            pos: btnPos,
            width: rect.width,
            height: rect.height,
            outline: {
              width: 4.,
              color: k->Color.fromHex("#c10007"),
            },
          })

          k->Context.drawText({
            text: "Play Again",
            font: PkmnFont.font,
            size: 20.,
            pos: btnPos->Vec2.Local.add(k->Context.vec2Local(20., 15.)),
          })
        },
      }),
    ])

    onClick(btn, () => {
      k->Context.go("game")
    })

    let defaultCursor = k->Context.getCursor

    onHover(btn, () => {
      k->Context.setCursor(Pointer)
    })

    onHoverEnd(btn, () => {
      k->Context.setCursor(defaultCursor)
    })
  }
}

let sceneName = "game-over"

let scene = (teamWhoLost: Team.t) => {
  PkmnFont.load(k)
  k->Context.onLoad(() => {
    GameOverScreen.make(k, ~teamWhoLost)
  })
}
