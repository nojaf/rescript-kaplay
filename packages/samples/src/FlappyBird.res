open Kaplay
open GameContext

type gameState = {
  mutable score: int,
  mutable gameOver: bool,
}

module Events = {
  let score = "score"
  let gameOver = "gameOver"
}

module Bird = {
  type t

  include Pos.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Body.Comp({type t = t})
  include Color.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Area.Comp({type t = t})
  include Rotate.Comp({type t = t})
  include OffScreen.Comp({type t = t})

  let tag = "bird"

  let make = () => {
    k->Context.add([
      k->addPosFromVec2(k->Context.center),
      k->addSprite("pidgeotto", ~options={flipX: true}),
      k->addBody,
      k->addColor(k->Context.colorFromHex("#ffb86a")),
      k->addAnchorCenter,
      k->addArea,
      k->addRotate(0.),
      k->addOffScreen(~options={destroy: true}),
      Context.tag(tag),
    ])
  }
}

module Pipe = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Move.Comp({type t = t})
  include Area.Comp({type t = t})
  include OffScreen.Comp({type t = t})
  include Rect.Comp({type t = t})
  include Color.Comp({type t = t})
  include Outline.Comp({type t = t})

  let width = 50.
  let tag = "pipe"

  let make = (isTop: bool, height: float): t => {
    let x = k->Context.width - width
    let y = isTop ? 0. : k->Context.height - height
    let pipe =
      k->Context.add([
        k->addPos(x, y),
        k->addRect(width, height),
        k->addColor(k->Context.colorFromHex("#bbf451")),
        k->addMove(k->Context.vec2Left, 100.),
        k->addOffScreen(~options={destroy: true}),
        k->addArea,
        k->addOutline(~width=3, ~color=k->Context.colorFromHex("#404040")),
        Context.tag(tag),
      ])

    pipe->onCollide(Bird.tag, (_bird: Bird.t, _collision) => {
      k.debug->Debug.log("collision, game over")
    })

    if isTop {
      let ctrl = ref(None)

      ctrl :=
        Some(
          pipe->onUpdateWithController(() => {
            if pipe->getPosX < k->Context.width / 2. {
              // Remove the event controller
              switch ctrl.contents {
              | None => ()
              | Some(ctrl) => ctrl->KEventController.cancel
              }

              // Trigger the score event
              trigger(pipe, Events.score, 1)
            }
          }),
        )
    }

    pipe
  }
}

let makeGameState = (): gameState => {
  {
    score: 0,
    gameOver: false,
  }
}

let scene = () => {
  k->Context.loadSprite("pidgeotto", "sprites/pidgeotto-rb.png")
  k->Context.setBackground(k->Context.colorFromHex("#cefafe"))

  k->Context.setGravity(100.)

  let gameState = makeGameState()

  let bird = Bird.make()

  k
  ->Context.onKeyRelease(key => {
    switch key {
    | Space => {
        bird->Bird.jump(150.)
        bird->Bird.rotateBy(-15.)
        k
        ->Context.tween(~from=-15., ~to_=0., ~duration=0.5, ~setValue=Bird.setAngle(bird, ...))
        ->ignore
      }
    | _ => ()
    }
  })
  ->ignore

  k->Context.on(~event=Events.score, ~tag=Pipe.tag, (_pipe: Pipe.t, score: int) => {
    gameState.score = gameState.score + score
    k.debug->Debug.log("score: " ++ Int.toString(gameState.score))
  })

  let _pipe = Pipe.make(true, 400.)
  let _buttomPipe = Pipe.make(false, 400.)
}
