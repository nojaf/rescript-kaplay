open Pixi

@val
external window: Application.resizeTarget = "window"

@scope(("document", "body"))
external appendChild: Application.canvasElement => unit = "appendChild"

let app = Application.make()

let setup = async () => {
  await app->Application.init({
    background: "#1099bb",
    resizeTo: window,
  })

  appendChild(app->Application.canvas)
}

let preload = async () => {
  let assets = [
    {
      Assets.alias: "background",
      src: "https://pixijs.com/assets/tutorials/fish-pond/pond_background.jpg",
    },
    {alias: "fish1", src: "https://pixijs.com/assets/tutorials/fish-pond/fish1.png"},
    {alias: "fish2", src: "https://pixijs.com/assets/tutorials/fish-pond/fish2.png"},
    {alias: "fish3", src: "https://pixijs.com/assets/tutorials/fish-pond/fish3.png"},
    {alias: "fish4", src: "https://pixijs.com/assets/tutorials/fish-pond/fish4.png"},
    {alias: "fish5", src: "https://pixijs.com/assets/tutorials/fish-pond/fish5.png"},
    {alias: "overlay", src: "https://pixijs.com/assets/tutorials/fish-pond/wave_overlay.png"},
    {
      alias: "displacement",
      src: "https://pixijs.com/assets/tutorials/fish-pond/displacement_map.png",
    },
    {
      alias: "sprites/squirte-sheet.png",
      src: "/sprites/squirte-sheet.png"
    }
  ]
  let _ = await Assets.loadMany(assets)
}

let main = async () => {
  await setup()
  await preload()

  AddBackground.addBackground(app)
  AddFishes.addFishes(app)
  let squirtle = await Squirtle.make(app)

  let fishes = {
    let fishContainer = app.stage.children->Array.find(c => c.label == "fish_container")
    switch fishContainer {
    | None => []
    | Some(container) => container.children->Array.map(AddFishes.fromContainer)
    }
  }

  app.ticker->Ticker.add(time => AddFishes.animateFishes(app, fishes, time))

  let tickerObservable = Rxjs.Observable.make(subscriber => {
    let tick = delta => subscriber.next(delta)
    Ticker.add(app.ticker, tick)
    () => app.ticker->Ticker.remove(tick)
  })

  let speed = 5.

  let squirtlePositionObservable = {
    open Rxjs

    combineLatest(Keys.keyMapObservable, tickerObservable)->pipe(
      scan(((x, y), (keys, tick: Ticker.t)) => {
        let hasKey = key => keys->Set.has(key) ? speed *. tick.deltaTime : 0.
        let nextX = x + hasKey("ArrowRight") - hasKey("ArrowLeft")
        let nextY = y + hasKey("ArrowDown") - hasKey("ArrowUp")
        (nextX, nextY)
      }, (squirtle.x, squirtle.y)),
    )
  }

  squirtlePositionObservable->Rxjs.Observable.subscribe(((x, y)) => {
    squirtle.x = x
    squirtle.y = y
  })
}

Promise.done(main())
