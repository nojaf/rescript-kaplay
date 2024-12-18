/// https://pixijs.download/release/docs/maths.Rectangle.html
module Rectangle = {
  type t = {
    width: float,
    height: float,
  }
}

/// https://pixijs.download/release/docs/maths.ObservablePoint.html
module ObservablePoint = {
  type t = {
    mutable x: int,
    mutable y: int,
  }

  @send
  external setBoth: (t, float) => unit = "set"

  @send
  external set: (t, float, float) => unit = "set"
}

/// https://pixijs.download/release/docs/scene.Container.html
module Container = {
  type rec t = {
    mutable x: float,
    mutable y: float,
    mutable rotation: float,
    mutable width: float,
    mutable height: float,
    mutable scale: ObservablePoint.t,
    mutable label: string,
    children: array<t>,
  }

  @new @module("pixi.js")
  external make: unit => t = "Container"

  @send @variadic
  external addChild: (t, array<t>) => unit = "addChild"
}

/// https://pixijs.download/release/docs/ticker.Ticker.html
module Ticker = {
  type t = {deltaTime: float}

  type tickerCallback = t => unit

  @send
  external add: (t, tickerCallback) => unit = "add"

  @send
  external remove: (t, tickerCallback) => unit = "remove"
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

  type unresolvedAsset = {
    alias: string,
    src: string,
  }

  @scope("Assets") @module("pixi.js")
  external loadMany: array<unresolvedAsset> => promise<Texture.t> = "load"
}

/// https://pixijs.download/release/docs/scene.Sprite.html
module Sprite = {
  type t = {
    ...Container.t,
    anchor: ObservablePoint.t,
  }

  @module("pixi.js") @new
  external make: Texture.t => t = "Sprite"

  @module("pixi.js") @scope("Sprite")
  external from: string => t = "from"

  external asContainer: t => Container.t = "%identity"
}
