open Kaplay

@scope("import.meta.env")
external baseUrl: string = "BASE_URL"

let k = Context.kaplay(
  ~initOptions={
    background: "#cefafe",
    global: false,
    scale,
    crisp: true,
    width: 800,
    height: 400,
  },
)

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
  let menu = "menu"
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
        k->addSprite(spriteName, ~options={flipX: true, height: 35.}),
        k->addBody,
        k->addColor(k->Color.fromHex("#ffb86a")),
        k->addAnchorCenter,
        k->addArea,
        k->addRotate(0.),
        k->addOffScreen(~options={destroy: true}),
        Context.tag(tag),
      ])

    bird->onExitScreen(() => {
      bird->trigger(Events.gameOver, ())
    })

    let fly = (bird: t) => {
      bird->jump(100.)
      bird->rotateBy(-15.)
      k
      ->Context.tween(~from=-15., ~to_=0., ~duration=0.5, ~setValue=setAngle(bird, ...))
      ->ignore
    }

    k->Context.onKeyRelease(key => {
      switch key {
      | Space => fly(bird)
      | _ => ()
      }
    })

    k
    ->Context.onTouchEnd((_, _) => {
      fly(bird)
    })
    ->ignore

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

  let tag = "pipe"
  let speed = 200.
  /**
 `Pipes.make(gap)` create a pipe with a gap of `gap` procent.
 */
  let make = (gap: float) => {
    let x = k->Context.width
    let width = 40.
    let gapHeight = k->Context.height * gap
    let remainingHeight = k->Context.height - gapHeight
    let topPipeHeight = k->Context.randf(0.20, 0.80) *. remainingHeight
    let bottomPipeHeight = remainingHeight - topPipeHeight

    let topPipe: t =
      k->Context.add([
        k->addPos(x, 0.),
        k->addRect(width, topPipeHeight),
        k->addColor(k->Color.fromHex("#bbf451")),
        k->addMove(k->Context.vec2Left, speed),
        k->addOffScreen(~options={destroy: true}),
        k->addArea,
        k->addOutline(~width=3., ~color=k->Color.fromHex("#404040")),
        Context.tag(tag),
      ])

    let bottomPipe: t =
      k->Context.add([
        k->addPos(x, k->Context.height - bottomPipeHeight),
        k->addRect(width, bottomPipeHeight),
        k->addColor(k->Color.fromHex("#bbf451")),
        k->addMove(k->Context.vec2Left, speed),
        k->addArea,
        k->addOutline(~width=3., ~color=k->Color.fromHex("#404040")),
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
      k->addColor(k->Color.fromHex("#024a70")),
      k->addText(text, ~options={size: 24.}),
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

let menu = () => {
  open Menu
  make(
    k,
    "Flappy Bird",
    [
      {label: "Play", action: () => k->Context.go(Scenes.game)},
      {
        label: "Play fullscreen",
        action: () => {
          k->Context.setFullscreen(true)
          k->Context.go(Scenes.game)
        },
      },
    ],
    ~hoverColor="#0069a8",
  )
}

let game = () => {
  k->Context.loadSprite(Bird.spriteName, `${baseUrl}/sprites/pidgeotto-rb.png`)
  // Check https://achtaitaipai.github.io/pfxr/ to make your own sounds
  k->Context.loadSound(Sounds.score, `${baseUrl}/sounds/score.wav`)
  k->Context.loadSound(Sounds.die, `${baseUrl}/sounds/die.wav`)

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
  open Menu
  make(
    k,
    "Game Over",
    [
      {label: "Score: " ++ Int.toString(score)},
      {label: "Replay", action: () => k->Context.go(Scenes.game)},
      {label: "Menu", action: () => k->Context.go(Scenes.menu)},
    ],
    ~hoverColor="#0069a8",
  )
}

k->Context.scene(Scenes.menu, menu)
k->Context.scene(Scenes.game, game)
k->Context.scene(Scenes.gameOver, gameOver)
k->Context.go(Scenes.menu)
