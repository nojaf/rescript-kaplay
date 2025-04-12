open Kaplay

let screen = {
  "width": 720,
  "height": 280,
}

let k = kaplay(
  ~initOptions={
    width: screen["width"],
    height: screen["height"],
    global: false,
    background: "#6495ED",
    scale: 1.,
  },
)

k->setGravity(250.)
k.debug->Debug.setInspect(true)

k->loadSprite(
  "squirtle",
  "sprites/squirtle.png",
  ~options={
    sliceX: 5,
    sliceY: 1,
    // frames: [
    //   k->quad(0, 0, 34, 39),
    //   k->quad(35, 1, 33, 37),
    //   k->quad(70, 0, 32, 38),
    //   k->quad(104, 1, 32, 36),
    //   k->quad(137, 0, 30, 39),
    // ],
    anims: dict{
      "idle": ({frames: [0]}: loadSpriteAnimation),
      "walk": {frames: [1, 2, 3, 2], loop: true, speed: 12.},
      "jump": {frames: [4], loop: false},
    },
  },
)

let ground = k->add([
  //
  k->rect(k->width, 24),
  k->pos(0, k->height - 24),
  k->color("#D97744"),
  k->area,
  k->body(~options={isStatic: true}),
])

let squirtle = k->add([
  //
  k->pos(200, 90),
  k->sprite(
    "squirtle",
    ~options={
      anim: "idle",
    },
  ),
  k->area,
  //   k->area(
  //     ~options={
  //       shape: mathRect(k, k->vec2(0, 0), 35, 39),
  //     },
  //   ),
  k->body,
  tag("squirtle"),
])

squirtle->GameObj.play("idle")

let speed = 200

k
->onKeyPress(key => {
  if squirtle->GameObj.isGrounded {
    switch key {
    | Left => {
        squirtle->GameObj.play("walk")
        squirtle->GameObj.setFlipX(false)
      }
    | Right => {
        squirtle->GameObj.play("walk")
        squirtle->GameObj.setFlipX(true)
      }
    | Space => {
        squirtle->GameObj.play("jump")
        squirtle->GameObj.jump(222.)
      }
    | _ => ()
    }
  } else {
    switch key {
    | Left => squirtle->GameObj.setFlipX(false)
    | Right => squirtle->GameObj.setFlipX(true)
    | _ => ()
    }
  }
})
->ignore

k
->onKeyDown(key => {
  switch key {
  | Left => squirtle->GameObj.move(-speed, 0)
  | Right => squirtle->GameObj.move(speed, 0)
  | _ => ()
  }
})
->ignore

k
->onKeyRelease(key => {
  switch key {
  | Left
  | Right if squirtle->GameObj.isGrounded =>
    squirtle->GameObj.play("idle")
  | _ => ()
  }
})
->ignore

squirtle
->GameObj.onGround(() => {
  if k->isKeyDown(Left) || k->isKeyDown(Right) {
    squirtle->GameObj.play("walk")
  } else {
    squirtle->GameObj.play("idle")
  }
})
->ignore

k
->onClick("squirtle", squirtle => {
  //   k.debug->Debug.log("squirtle clicked")
  // squirtle->GameObj.play("walk")
  let current = squirtle->GameObj.getFrame
  let max = squirtle->GameObj.numFrames
  squirtle->GameObj.setFrame((current + 1) % max)
})
->ignore
