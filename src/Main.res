open Pixi

@val
external window: Application.resizeTarget = "window"

@scope(("document", "body"))
external appendChild: Application.canvasElement => unit = "appendChild"

let main = async () => {
  let app = Application.make()
  await app->Application.init({
    background: "rebeccapurple",
    resizeTo: window,
  })

  appendChild(app->Application.canvas)

  let texture = await Assets.load("https://pixijs.com/assets/bunny.png")

  let bunny = Sprite.make(texture)

  bunny.anchor->ObservablePoint.setBoth(0.5)

  bunny.x = app.screen.width / 2
  bunny.y = app.screen.height / 2

  app.stage->Container.addChild([bunny->Sprite.asContainer])

  app.ticker->Ticker.add(time => {
    bunny.rotation = bunny.rotation + 0.025 * time.deltaTime
  })

  Console.log("Game rendered!")
}

Promise.done(main())
