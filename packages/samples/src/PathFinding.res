open Kaplay
open Kaplay.Context

let tileSize = 64.
let width = 12. *. tileSize
let height = 8. *. tileSize
let scale = min(1.5, min(innerWidth / width, innerHeight / height))

let k = Context.kaplay(
  ~initOptions={
    width: Float.toInt(width),
    height: Float.toInt(height),
    scale,
    background: "#f54900",
  },
)

module EmptyTile = {
  type t = unit

  include Rect.Comp({type t = t})
  include Outline.Comp({type t = t})
  include Tile.Comp({type t = t})

  let make = () => {
    [
      //
      addRect(k, tileSize, tileSize),
      addTile(k),
      addOutline(k, ~width=1., ~color=k->Color.fromHex("#000000")),
    ]
  }
}

module WallTile = {
  type t

  include Rect.Comp({type t = t})
  include Outline.Comp({type t = t})
  include Color.Comp({type t = t})
  include Tile.Comp({type t = t})

  let make = () => {
    [
      addRect(k, tileSize, tileSize),
      addTile(k),
      addOutline(k, ~width=1., ~color=k->Color.fromHex("#0AC0B0"), ~opacity=1.),
      addColor(k, k->Color.fromHex("#46ecd5")),
    ]
  }
}

module SquirtleTile = {
  type t

  include Sprite.Comp({type t = t})
  include Tile.Comp({type t = t})
  include Color.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Pos.Comp({type t = t})

  let make = () => {
    [
      addTile(k),
      addSprite(k, "squirtle", ~options={width: tileSize, height: tileSize}),
      addColor(k, k->Color.fromHex("#ADD8E6")),
      addAnchorCenter(k),
      addPos(k, tileSize / 2., tileSize / 2.),
      tag("squirtle"),
    ]
  }
}

module CharmanderTile = {
  type t

  include Sprite.Comp({type t = t})
  include Tile.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Agent.Comp({type t = t})
  include Color.Comp({type t = t})

  let make = () => {
    [
      addSprite(k, "charmander", ~options={width: tileSize, height: tileSize}),
      addAnchorCenter(k),
      addPos(k, tileSize / 2., tileSize / 2.),
      addTile(k),
      addColor(k, k->Color.fromHex("#FF746C")),
      addAgent(k, ~options={speed: 120., allowDiagonals: false}),
    ]
  }
}

module Text = {
  type t

  include Text.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Anchor.Comp({type t = t})

  let make = (): t => {
    k->Context.add([
      addText(k, "Press space to start", ~options={size: 20.}),
      addPos(k, k->Context.width - 20., k->Context.height - 20.),
      addAnchor(k, BottomRight),
    ])
  }
}

let onLoad = () => {
  let level = k->addLevel(
    ["############", "#          #", "#          #", "#          #", "############"],
    {
      tileWidth: tileSize,
      tileHeight: tileSize,
      tiles: dict{
        " ": EmptyTile.make,
        "#": WallTile.make,
      },
    },
  )

  let squirtle = level->Level.spawn(SquirtleTile.make(), k->vec2(1., 1.))
  let charmander = level->Level.spawn(CharmanderTile.make(), k->vec2(7., 4.))

  let _text = Text.make()
  let audio = ref(None)

  k->onKeyPress(key => {
    switch key {
    | Space => {
        let target = squirtle->SquirtleTile.getPos
        charmander->CharmanderTile.setTarget(target)
        switch audio.contents {
        | None => audio := Some(k->play("beast-in-black"))
        | Some(audio) =>
          if audio.paused {
            audio->AudioPlay.play
          } else {
            audio.paused = true
          }
        }
      }
    | _ => ()
    }
  })
}

k->loadSprite("squirtle", `${baseUrl}/sprites/squirtle-rb.png`)
k->loadSprite("charmander", `${baseUrl}/sprites/charmander-rb.png`)
k->loadMusic("beast-in-black", `${baseUrl}/sounds/beast-in-black.mp3`)

k->Context.onLoad(onLoad)
