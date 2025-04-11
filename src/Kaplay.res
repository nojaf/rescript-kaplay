module Debug = {
  type t

  @send
  external log: (t, string) => unit = "log"
}

type t = {debug: Debug.t}

type kaplayOptions = {}

@module("kaplay")
external kaplay: (~initOptions: kaplayOptions=?) => t = "default"

type loadSpriteAnimation = {
  from: int,
  to: int,
}

type loadSpriteOptions = {
  sliceX?: int,
  sliceY?: int,
  anims?: Dict.t<loadSpriteAnimation>,
}

@send
external loadSprite: (t, string, string, ~options: loadSpriteOptions=?) => unit = "loadSprite"

@unboxed
type key =
  | @as("left") Left
  | @as("right") Right
  | @as("up") Up
  | @as("down") Down
  | @as("space") Space
  | @as("enter") Enter

type kEventController

@send
external onKeyDown: (t, key => unit) => kEventController = "onKeyDown"

module GameObj = {
  type t

  @send
  external move: (t, int, int) => unit = "move"
}

module Vec2 = {
  type t
}

module SpriteComp = {
  type t = {
    id: string,
    width: int,
  }
}

module PosComp = {
  type t
}

@tag("id")
type comp =
  | Sprite(SpriteComp.t)
  | Pos(PosComp.t)

@send
external add: (t, array<comp>) => GameObj.t = "add"

@send
external sprite: (t, string) => comp = "sprite"

@send
external pos: (t, int, int) => comp = "pos"
