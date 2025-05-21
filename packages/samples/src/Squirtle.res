open Kaplay
open Kaplay.Context

open GameContext

module Squirtle = {
  type t

  include Pos.Comp({ type t = t })
  include Sprite.Comp({ type t = t })
  include Area.Comp({ type t = t })
  include Body.Comp({ type t = t })

  let make = (~x, ~y) => {
    k->Context.add([
      addPos(k, x, y),
      addSprite(k, "squirtle",   ~options={
        anim: "idle",
      }),
      addArea(k),
      addBody(k),
      tag("squirtle"),
    ])
  }
}

module Ground = {
  type t

  include Pos.Comp({ type t = t })
  include Area.Comp({ type t = t })
  include Rect.Comp({ type t = t })
  include Color.Comp({ type t = t })
  include Body.Comp({ type t = t })

  let make = () => {
    k->Context.add([
      addPos(k, 0., k->height - 24.),
      addRect(k, k->width, 24.),
      addColor(k, k->colorFromHex("#D97744")),
      addArea(k),
      addBody(k, ~options={isStatic: true})
    ])
  }
  
}

let scene = () => {
  k->setGravity(250.)
  k.debug->Debug.setInspect(true)

  let squirtleSpritesheetDimensions = {
    "width": 167.,
    "height": 39.,
  }

  let mkSquirtleQuad = (x: float, y: float, w: float, h: float) =>
    k->quad(
      x / squirtleSpritesheetDimensions["width"],
      y / squirtleSpritesheetDimensions["height"],
      w / squirtleSpritesheetDimensions["width"],
      h / squirtleSpritesheetDimensions["height"],
    )

  k->loadSprite(
    "squirtle",
    "sprites/squirtle.png",
    ~options={
      frames: [
        mkSquirtleQuad(0., 0., 34., 39.),
        mkSquirtleQuad(35., 1., 33., 37.),
        mkSquirtleQuad(70., 0., 32., 38.),
        mkSquirtleQuad(104., 1., 32., 36.),
        mkSquirtleQuad(137., 0., 30., 39.),
      ],
      anims: dict{
        "idle": ({frames: [0]}: loadSpriteAnimation),
        "walk": {frames: [1, 2, 3, 2], loop: true, speed: 12.},
        "jump": {frames: [4], loop: false},
      },
    },
  )

  let _ground = Ground.make()

  let squirtle = Squirtle.make(~x=200., ~y=90.)

  k.debug->Debug.log(squirtle->Squirtle.numFrames->Int.toString)

  squirtle->Squirtle.play("idle")

  let speed = 200.

  k
  ->onKeyPress(key => {
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
          squirtle->Squirtle.jump(222.)
        }
      | _ => ()
      }
    } else {
      switch key {
      | Left => squirtle->Squirtle.setFlipX(false)
      | Right =>  squirtle->Squirtle.setFlipX(true)
      | _ => ()
      }
    }
  })
  ->ignore

  k
  ->onKeyDown(key => {
    switch key {
    | Left => squirtle->Squirtle.move(k->vec2(-speed, 0.))
    | Right => squirtle->Squirtle.move(k->vec2(speed, 0.))
    | _ => ()
    }
  })
  ->ignore

  k
  ->onKeyRelease(key => {
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
    if k->isKeyDown(Left) || k->isKeyDown(Right) {
      squirtle->Squirtle.play("walk")
    } else {
      squirtle->Squirtle.play("idle")
    }
  })
  ->ignore

  k
  ->onClickWithTag("squirtle", squirtle => {
    //   k.debug->Debug.log("squirtle clicked")
    // squirtle->GameObj.play("walk")
    let current = squirtle->Squirtle.getFrame
    let max = squirtle->Squirtle.numFrames
    squirtle->Squirtle.setFrame((current + 1) % max)
  })
  ->ignore
}

let x = 799