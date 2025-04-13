open Kaplay
open KaplayContext

let speed = 10
let mapWidth = 1000
let mapHeight = 563
let gameWidth = k->width
let gameHeight = k->height

let cameraBounds = {
  "x": {
    "min": gameWidth / 2,
    "max": mapWidth - gameWidth / 2,
  },
  "y": {
    "min": gameHeight / 2,
    "max": mapHeight - gameHeight / 2,
  },
}

let scene = () => {
  k->loadSprite("bg", "middle-earth.webp")

  let map = k->add([
    k->pos(0, 0),
    k->sprite(
      "bg",
      ~options={
        width: mapWidth,
        height: mapHeight,
      },
    ),
    k->area,
  ])

  map->GameObj.onKeyDown(key => {
    let currentCamPos = k->getCamPos

    let move = switch key {
    | Left => k->vec2(-speed, 0)
    | Right => k->vec2(speed, 0)
    | Up => k->vec2(0, -speed)
    | Down => k->vec2(0, speed)
    | _ => k->vec2(0, 0)
    }
    let moveWithBounds = {
      let result = currentCamPos->Vec2.add(move)
      result.x = k->clamp(result.x, cameraBounds["x"]["min"], cameraBounds["x"]["max"])
      result.y = k->clamp(result.y, cameraBounds["y"]["min"], cameraBounds["y"]["max"])
      result
    }
    k->setCamPos(moveWithBounds)
  })
}
