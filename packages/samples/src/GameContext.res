open Kaplay.Context

@val @scope("screen")
external screenWidth: int = "width"

@val @scope("screen")
external screenHeight: int = "height"

@scope("Math")
external min: (int, int) => int = "min"

@scope("document") @return(nullable)
external getElementById: string => option<htmlCanvasElement> = "getElementById"

// The documentation has a canvas tag when used.
let maybeCanvas = getElementById("docs-canvas")

let initOptions = {
  global: false,
  background: "#05df72",
  scale: 1.,
}

let initOptions = switch maybeCanvas {
| Some(canvas) => {
    ...initOptions,
    canvas,
  }
| None => initOptions
}

let k = kaplay(~initOptions)

@scope("import.meta.env")
external baseUrl: string = "BASE_URL"