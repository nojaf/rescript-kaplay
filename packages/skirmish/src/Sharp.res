type input = {
  create: {
    width: int,
    height: int,
    channels: int,
    background: {
      r: int,
      g: int,
      b: int,
      alpha: int,
    },
  },
}

type t

@module("sharp")
external sharp: input => t = "default"

@module("sharp")
external sharpFromBuffer: RescriptBun.Buffer.t => t = "default"

type resizeOption = {
  width: int,
  height: int,
  fit: string,
  background?: {r: int, g: int, b: int, alpha: int},
}

@send
external resize: (t, resizeOption) => t = "resize"

@send
external png: t => t = "png"

@send
external toBuffer: t => promise<RescriptBun.Buffer.t> = "toBuffer"

type overlayOption = {
  input: RescriptBun.Buffer.t,
  top: int,
  left: int,
}

@send
external composite: (t, array<overlayOption>) => t = "composite"

@send
external toFile: (t, string) => promise<unit> = "toFile"

type trimOptions = {
  threshold?: float,
  lineArt?: bool,
}

@send
external trim: (t, ~options: trimOptions=?) => t = "trim"
