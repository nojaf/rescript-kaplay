open Pixi

let addBunny = (app: Application.t) => {
  let bunny = Sprite.from("bunny")

  bunny.anchor->ObservablePoint.setBoth(0.5)

  bunny.x = app.screen.width /. 2.
  bunny.y = app.screen.height /. 2.

  app.stage->Container.addChild([bunny->Sprite.asContainer])

  bunny
}
