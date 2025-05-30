open Kaplay
open GameContext

type gameState = {
  mutable score: int,
  /** in seconds */
  mutable speed: float,
  mutable lastUpdate: float,
  /** in procent */
  mutable gap: float,
}

module Events = {
  let score = "score"
  let gameOver = "gameOver"
}

module Sounds = {
  let score = "score"
  let die = "die"
}

module Scenes = {
  let game = "flappy-bird"
  let gameOver = "gameOver"
}

module Bird = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Body.Comp({type t = t})
  include Color.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Area.Comp({type t = t})
  include Rotate.Comp({type t = t})
  include OffScreen.Comp({type t = t})

  let tag = "bird"
  let spriteName = "pidgeotto"

  let make = () => {
    let bird: t =
      k->Context.add([
        k->addPosFromVec2(k->Context.center),
        k->addSprite(spriteName, ~options={flipX: true}),
        k->addBody,
        k->addColor(k->Context.colorFromHex("#ffb86a")),
        k->addAnchorCenter,
        k->addArea,
        k->addRotate(0.),
        k->addOffScreen(~options={destroy: true}),
        Context.tag(tag),
      ])

    bird->onExitScreen(() => {
      bird->trigger(Events.gameOver, ())
    })

    k->Context.onKeyRelease(key => {
      switch key {
      | Space => {
          bird->jump(100.)
          bird->rotateBy(-15.)
          k
          ->Context.tween(~from=-15., ~to_=0., ~duration=0.5, ~setValue=setAngle(bird, ...))
          ->ignore
        }
      | _ => ()
      }
    })

    bird
  }
}

module Pipes = {
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
  let speed = 200.
  /**
 `Pipes.make(gap)` create a pipe with a gap of `gap` procent.
 */
  let make = (gap: float) => {
    let x = k->Context.width - width
    let gapHeight = k->Context.height * gap
    let remainingHeight = k->Context.height - gapHeight
    let topPipeHeight = k->Context.randf(0.20, 0.80) *. remainingHeight
    let bottomPipeHeight = remainingHeight - topPipeHeight

    let topPipe: t =
      k->Context.add([
        k->addPos(x, 0.),
        k->addRect(width, topPipeHeight),
        k->addColor(k->Context.colorFromHex("#bbf451")),
        k->addMove(k->Context.vec2Left, speed),
        k->addOffScreen(~options={destroy: true}),
        k->addArea,
        k->addOutline(~width=3, ~color=k->Context.colorFromHex("#404040")),
        Context.tag(tag),
      ])

    let bottomPipe: t =
      k->Context.add([
        k->addPos(x, k->Context.height - bottomPipeHeight),
        k->addRect(width, bottomPipeHeight),
        k->addColor(k->Context.colorFromHex("#bbf451")),
        k->addMove(k->Context.vec2Left, speed),
        k->addArea,
        k->addOutline(~width=3, ~color=k->Context.colorFromHex("#404040")),
        Context.tag(tag),
      ])

    topPipe->onCollide(Bird.tag, (_bird: Bird.t, _collision) => {
      trigger(topPipe, Events.gameOver, ())
    })

    bottomPipe->onCollide(Bird.tag, (_bird: Bird.t, _collision) => {
      trigger(bottomPipe, Events.gameOver, ())
    })

    let ctrl = ref(None)

    ctrl :=
      Some(
        topPipe->onUpdateWithController(() => {
          if topPipe->getPosX < k->Context.width / 2. {
            // Remove the event controller
            switch ctrl.contents {
            | None => ()
            | Some(ctrl) => ctrl->KEventController.cancel
            }

            // Trigger the score event
            trigger(topPipe, Events.score, 1)
          }
        }),
      )
  }
}

module Text = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Color.Comp({type t = t})
  include Text.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Z.Comp({type t = t})

  let make = (text: string, x: float, y: float, ~anchor: anchor=Center) => {
    k->Context.add([
      k->addPos(x, y),
      k->addColor(k->Context.colorFromHex("#024a70")),
      k->addText(text),
      k->addZ(1),
      k->addAnchor(anchor),
    ])
  }
}

let makeGameState = (): gameState => {
  {
    score: 0,
    speed: 2.0,
    lastUpdate: 0.,
    gap: 0.40,
  }
}

let scene = () => {
  k->Context.loadSprite(Bird.spriteName, "sprites/pidgeotto-rb.png")
  // Check https://achtaitaipai.github.io/pfxr/ to make your own sounds
  k->Context.loadSound(Sounds.score, "sounds/score.wav")
  k->Context.loadSound(Sounds.die, "sounds/die.wav")
  k->Context.setBackground(k->Context.colorFromHex("#cefafe"))

  k->Context.setGravity(100.)

  let gameState = makeGameState()

  let bird = Bird.make()

  let scoreText = Text.make("Score: " ++ Int.toString(gameState.score), 25., 25., ~anchor=TopLeft)

  let helpText = Text.make(
    "Press <space> to go up!",
    25.0,
    k->Context.height - 25.,
    ~anchor=BottomLeft,
  )
  k->Context.wait(2.5, () => {
    helpText->Text.destroy
  })

  k->Context.on(~event=Events.score, ~tag=Pipes.tag, (_pipe: Pipes.t, score: int) => {
    let birdIsColliding = bird->Bird.getCollisions->Array.some(_ => true)
    if !birdIsColliding {
      gameState.score = gameState.score + score
      gameState.gap = gameState.gap - 0.02
      scoreText->Text.setText("Score: " ++ Int.toString(gameState.score))
      let _ = k->Context.play(Sounds.score)
    }
  })

  k->Context.on(~event=Events.gameOver, ~tag=Pipes.tag, (_pipe: Pipes.t, _) => {
    let _ = k->Context.play(Sounds.die)
    k->Context.go(Scenes.gameOver, ~data=gameState.score)
  })

  Pipes.make(gameState.gap)

  k->Context.onUpdate(() => {
    gameState.lastUpdate = gameState.lastUpdate + k->Context.dt
    if gameState.lastUpdate > gameState.speed {
      Pipes.make(gameState.gap)
      gameState.lastUpdate = 0.
    }
  })
}

let gameOver = (score: int) => {
  let centerX = k->Context.center->Vec2.x
  let y = k->Context.height / 4.
  let _title = Text.make("Game Over", centerX, y)
  let _score = Text.make("Score: " ++ Int.toString(score), centerX, y + 100.)
  let _replay = Text.make("(Click to replay)", centerX, y + 200.)

  k->Context.onClick(() => {
    k->Context.go(Scenes.game)
  })
}

k->Context.scene(Scenes.game, scene)
k->Context.scene(Scenes.gameOver, gameOver)
