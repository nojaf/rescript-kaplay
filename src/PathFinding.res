open Kaplay
open KaplayContext

let scene = () => {
  k->loadSprite("squirtle", "/sprites/squirtle-rb.png")
  k->loadSprite("charmander", "/sprites/charmander-rb.png")
  k->loadMusic("beast-in-black", "sounds/beast-in-black.mp3")

  let tileSize = 64
  let level = k->addLevel(
    [
      //
      "##########",
      "#  S     #",
      "#        #",
      "#        #",
      "##########",
    ],
    {
      tileWidth: tileSize,
      tileHeight: tileSize,
      tiles: dict{
        " ": () => [
          k->rect(tileSize, tileSize),
          k->outline(~width=1, ~color=k->colorFromHex("#000000")),
          k->opacity(1.),
        ],
        "#": () => [
          //
          k->rect(tileSize, tileSize),
          k->tile,
          k->color(k->colorFromHex("#00EE00")),
          k->outline(~width=2, ~color=k->colorFromHex("#0AC0B0"), ~opacity=1.),
        ],
        "S": () => [
          k->tile,
          k->sprite("squirtle", ~options={width: tileSize, height: tileSize}),
          k->pos(tileSize / 2, tileSize / 2),
          k->anchorCenter,
          k->color(k->colorFromHex("#ADD8E6")),
          tag("squirtle"),
        ],
      },
    },
  )

  let charmander = level->Level.spawn(
    [
      //
      k->sprite("charmander", ~options={width: tileSize, height: tileSize}),
      k->anchorCenter,
      k->pos(tileSize / 2, tileSize / 2),
      k->tile,
      k->color(k->colorFromHex("#FF746C")),
      k->agent(~options={speed: 120., allowDiagonals: false}),
    ],
    k->vec2(7., 4.),
  )

  k
  ->onKeyPress(key => {
    switch key {
    | Space =>
      switch k->getGameObjects("squirtle", ~options={recursive: true})->Array.get(0) {
      | None => k.debug->Debug.log("No squirtle found")
      | Some(squartle) => {
          let target = squartle->GameObj.getPos
          charmander->GameObj.setTarget(target)
          k
          ->play("beast-in-black")
          ->ignore
        }
      }
    | _ => ()
    }
  })
  ->ignore
}
