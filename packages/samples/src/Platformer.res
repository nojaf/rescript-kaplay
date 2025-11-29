open Kaplay

module Rectangle = Kaplay.Math.Rect

let k = Context.kaplay(
  ~initOptions={
    background: "#dff2fe",
    global: false,
    width: 800,
    height: 400,
    scale,
  },
)

module GameBounds = {
  type t

  include Pos.Comp({type t = t})
  include Area.Comp({type t = t})
  include Body.Comp({type t = t})

  let make = () => {
    let leftPos = k->Context.vec2ZeroLocal
    let _left = k->Context.add([
      addPosFromVec2(k, leftPos),
      addArea(
        k,
        ~options={
          // Math shapes use world coordinates
          shape: k
          ->Rectangle.make(k->Context.vec2ZeroWorld, 1., k->Context.height)
          ->Rectangle.asShape,
        },
      ),
      addBody(k, ~options={isStatic: true}),
    ])

    let rightPos = k->Context.vec2Local(k->Context.width - 1., 0.)

    let _right = k->Context.add([
      addPosFromVec2(k, rightPos),
      addArea(
        k,
        ~options={
          // Math shapes use world coordinates
          shape: k
          ->Rectangle.make(k->Context.vec2ZeroWorld, 1., k->Context.width - 1.)
          ->Rectangle.asShape,
        },
      ),
      addBody(k, ~options={isStatic: true}),
    ])
  }
}

module Squirtle = {
  type t

  include Pos.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Area.Comp({type t = t})
  include Body.Comp({type t = t})
  include OffScreen.Comp({type t = t})

  let tag = "squirtle"
  let jumpSpeed = 222.

  let make = (~x, ~y) => {
    k->Context.add([
      addPos(k, x, y),
      addSprite(
        k,
        "squirtle",
        ~options={
          anim: "idle",
        },
      ),
      addArea(k),
      addBody(k),
      Context.tag(tag),
    ])
  }
}

module Ground = {
  type t

  include Pos.Comp({type t = t})
  include Area.Comp({type t = t})
  include Rect.Comp({type t = t})
  include Color.Comp({type t = t})
  include Body.Comp({type t = t})

  let make = (~x, ~y, ~w, ~h) => {
    k->Context.add([
      addPos(k, x, y),
      addRect(k, w, h),
      addColor(k, k->Color.fromHex("#D97744")),
      addArea(k),
      addBody(k, ~options={isStatic: true}),
    ])
  }
}

module Coin = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Area.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Z.Comp({type t = t})

  let height = 20.

  let spawn = (~x, ~y) => {
    let coin: t = k->Context.add([
      //
      addPos(k, x, y),
      addArea(k),
      addSprite(k, "coin", ~options={anim: "spin", height}),
      addZ(k, -1),
    ])

    coin->onCollide(Squirtle.tag, (_squirtle, _) => {
      coin->destroy
      k->Context.play("score")->ignore
    })

    ()
  }
}

let scene = () => {
  k->Context.setGravity(250.)

  k->Context.loadSound("score", `${baseUrl}/sounds/score.wav`)

  let squirtleSpritesheetDimensions = {
    "width": 167.,
    "height": 39.,
  }

  let mkSquirtleQuad = (x: float, y: float, w: float, h: float) =>
    k->Context.quad(
      x / squirtleSpritesheetDimensions["width"],
      y / squirtleSpritesheetDimensions["height"],
      w / squirtleSpritesheetDimensions["width"],
      h / squirtleSpritesheetDimensions["height"],
    )

  k->Context.loadSprite(
    "squirtle",
    `${baseUrl}/sprites/squirtle.png`,
    ~options={
      frames: [
        mkSquirtleQuad(0., 0., 34., 39.),
        mkSquirtleQuad(35., 1., 33., 37.),
        mkSquirtleQuad(70., 0., 32., 38.),
        mkSquirtleQuad(104., 1., 32., 36.),
        mkSquirtleQuad(137., 0., 30., 39.),
      ],
      anims: dict{
        "idle": ({frames: [0]}: Context.loadSpriteAnimation),
        "walk": {frames: [1, 2, 3, 2], loop: true, speed: 12.},
        "jump": {frames: [4], loop: false},
      },
    },
  )

  let mkCoinQuad = (x: float, w: float) => k->Context.quad(x / 384., 0., w / 384., 1.)

  k->Context.loadSprite(
    "coin",
    `${baseUrl}/sprites/coin.png`,
    ~options={
      frames: [
        mkCoinQuad(0., 70.),
        mkCoinQuad(92., 48.),
        mkCoinQuad(180., 31.),
        mkCoinQuad(250., 49.),
        mkCoinQuad(320., 64.),
      ],
      anims: dict{
        "spin": {Context.frames: [0, 1, 2, 3, 4], loop: true},
      },
    },
  )

  let _gameBounds = GameBounds.make()
  let ground = Ground.make(~x=0., ~y=k->Context.height - 24., ~w=k->Context.width, ~h=24.)
  let _floatingGround = Ground.make(
    //
    ~x=k->Context.width / 3.,
    ~y=k->Context.height - 4. * 24.,
    ~w=k->Context.width / 6.,
    ~h=24.,
  )

  let squirtle = Squirtle.make(~x=200., ~y=k->Context.height * 0.6)
  squirtle->Squirtle.play("idle")

  Coin.spawn(
    ~x=k->Context.width / 2.,
    ~y=k->Context.randf(
      k->Context.height - Coin.height - Squirtle.jumpSpeed + squirtle->Squirtle.getHeight,
      k->Context.height - Coin.height - ground->Ground.getHeight,
    ),
  )

  let speed = 200.

  k
  ->Context.onKeyPress(key => {
    if squirtle->Squirtle.isGrounded {
      switch key {
      | Left => {
          squirtle->Squirtle.play("walk")
          squirtle->Squirtle.setFlipX(false)
        }
      | Right => {
          squirtle->Squirtle.play("walk")
          squirtle->Squirtle.setFlipX(true)
        }
      | Space => {
          squirtle->Squirtle.play("jump")
          squirtle->Squirtle.jump(Squirtle.jumpSpeed)
        }
      | _ => ()
      }
    } else {
      switch key {
      | Left => squirtle->Squirtle.setFlipX(false)
      | Right => squirtle->Squirtle.setFlipX(true)
      | _ => ()
      }
    }
  })
  ->ignore

  k
  ->Context.onKeyDown(key => {
    switch key {
    | Left => squirtle->Squirtle.move(k->Context.vec2World(-speed, 0.))
    | Right => squirtle->Squirtle.move(k->Context.vec2World(speed, 0.))
    | _ => ()
    }
  })
  ->ignore

  k
  ->Context.onKeyRelease(key => {
    switch key {
    | Left
    | Right if squirtle->Squirtle.isGrounded =>
      squirtle->Squirtle.play("idle")
    | _ => ()
    }
  })
  ->ignore

  squirtle
  ->Squirtle.onGround(() => {
    if k->Context.isKeyDown(Left) || k->Context.isKeyDown(Right) {
      squirtle->Squirtle.play("walk")
    } else {
      squirtle->Squirtle.play("idle")
    }
  })
  ->ignore

  k
  ->Context.onClickWithTag("squirtle", squirtle => {
    let current = squirtle->Squirtle.getFrame
    let max = squirtle->Squirtle.numFrames
    squirtle->Squirtle.setFrame((current + 1) % max)
  })
  ->ignore
}

k->Context.scene("game", scene)
k->Context.go("game")
