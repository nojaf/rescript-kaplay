/// https://pixijs.download/release/docs/maths.Rectangle.html
module Rectangle = {
  type t = {
    width: int,
    height: int,
  }
}

/// https://pixijs.download/release/docs/scene.Container.html
module Container = {
  type t = {
    mutable x: int,
    mutable y: int,
    mutable rotation: float,
  }

  @send @variadic
  external addChild: (t, array<t>) => unit = "addChild"
}

/// https://pixijs.download/release/docs/ticker.Ticker.html
module Ticker = {
  type t = {deltaTime: float}

  type tickerCallback = t => unit

  @send
  external add: (t, tickerCallback) => unit = "add"
}

/// https://pixijs.download/release/docs/app.Application.html
module Application = {
  type t = {screen: Rectangle.t, stage: Container.t, ticker: Ticker.t}

  @module("pixi.js") @new
  external make: unit => t = "Application"

  type resizeTarget

  type initOptions = {
    background?: string,
    resizeTo?: resizeTarget,
  }

  @send
  external init: (t, initOptions) => promise<unit> = "init"

  type canvasElement

  @get
  external canvas: t => canvasElement = "canvas"
}

module Texture = {
  type t
}

/// https://pixijs.download/release/docs/assets.Assets.html
module Assets = {
  @scope("Assets") @module("pixi.js")
  external load: string => promise<Texture.t> = "load"
}

/// https://pixijs.download/release/docs/maths.ObservablePoint.html
module ObservablePoint = {
  type t

  @send
  external setBoth: (t, float) => unit = "set"

  @send
  external set: (t, float, float) => unit = "set"
}

/// https://pixijs.download/release/docs/scene.Sprite.html
module Sprite = {
  type t = {
    ...Container.t,
    anchor: ObservablePoint.t,
  }

  @module("pixi.js") @new
  external make: Texture.t => t = "Sprite"

  external asContainer: t => Container.t = "%identity"
}
