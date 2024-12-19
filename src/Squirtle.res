open Pixi

let spritesheet = {
  "meta": {
    "image": "sprites/squirte-sheet.png",
    "format": "RGBA8888",
    "size": {"w": 398, "h": 311},
    "scale": 1,
  },
  "frames": {
    "rest": {
      "frame": {"x": 8, "y": 8, "w": 34, "h": 38},
      "sourceSize": {"w": 34, "h": 38},
      "spriteSourceSize": {"x": 8, "y": 8, "w": 34, "h": 38},
    },
  },
}

let make = async (app: Application.t) => {
  let texture = Texture.from(spritesheet["meta"]["image"])
  let spriteSheet = Spritesheet.make(texture, Obj.magic(spritesheet))
  await spriteSheet->Spritesheet.parse
  let squirtle = Sprite.make(Dict.getUnsafe(spriteSheet.textures, "rest"))

  squirtle.anchor->ObservablePoint.setBoth(0.5)

  squirtle.x = app.screen.width /. 2.
  squirtle.y = app.screen.height /. 2.

  app.stage->Container.addChild([squirtle->Sprite.asContainer])

  squirtle
}
