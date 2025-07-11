open Kaplay
open Kaplay.Context

let k = Context.kaplay(
  ~initOptions={width: 800, height: 400, scale, background: "#f54900", crisp: true},
)

let speed = 10.
let mapWidth = 1000.
let mapHeight = 563.
let gameWidth = k->width
let gameHeight = k->height

let cameraBounds = {
  "x": {
    "min": gameWidth / 2.,
    "max": mapWidth - gameWidth / 2.,
  },
  "y": {
    "min": gameHeight / 2.,
    "max": mapHeight - gameHeight / 2.,
  },
}

let zeroVector = k->vec2(0., 0.)

// Velocity for momentum effect
let cameraVelocity = ref(zeroVector)
let lastTouchStart = ref(zeroVector)
let isDragging = ref(false)

let updateCamera = (result: Vec2.t) => {
  let currentCamPos = k->getCamPos
  let moveWithBounds = {
    let result = currentCamPos->Vec2.add(result)
    result.x = k->clampFloat(result.x, cameraBounds["x"]["min"], cameraBounds["x"]["max"])
    result.y = k->clampFloat(result.y, cameraBounds["y"]["min"], cameraBounds["y"]["max"])
    result
  }

  k
  ->tween(
    ~from=currentCamPos,
    ~to_=moveWithBounds,
    ~duration=0.100,
    ~setValue=v => k->setCamPos(v),
    ~easeFunc=k.easings.linear,
  )
  ->ignore

  //   k->setCamPos(moveWithBounds)
}

module Text = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Text.Comp({type t = t})
  include Color.Comp({type t = t})

  let make = (~x, ~y, text): t => {
    k->Context.add([
      addPos(k, x, y),
      addText(k, text, ~options={size: 20.}),
      addColor(k, k->Color.fromHex("#ffe62d")),
    ])
  }
}

module Map = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Area.Comp({type t = t})

  let make = () => {
    k->Context.add([
      addPos(k, 0., 0.),
      addSprite(
        k,
        "bg",
        ~options={
          width: mapWidth,
          height: mapHeight,
        },
      ),
      addArea(k),
    ])
  }
}

let onLoad = () => {
  let map = Map.make()

  let touchStart = pos => {
    lastTouchStart := pos
    isDragging := true
    cameraVelocity := zeroVector // Reset velocit
  }

  k->onTouchStart((pos, _touch) => {
    touchStart(pos)
  })

  let touchMove = pos => {
    if isDragging.contents {
      let delta = pos->Vec2.sub(lastTouchStart.contents)
      cameraVelocity := delta->Vec2.scale(k->vec2(-150., -100.)) // Scale for responsiveness
      lastTouchStart := pos
    }
  }

  // On touch move (update velocity)
  k->onTouchMove((pos, _touch) => {
    touchMove(pos)
  })

  let touchEnd = () => {
    isDragging := false
  }

  // On touch end (apply momentum)
  k->onTouchEnd((_, _touch) => {
    touchEnd()
  })

  // Update camera position every frame (momentum effect)
  k->onUpdate(() => {
    if !isDragging.contents {
      // Apply velocity to camera
      let currentVelocity = cameraVelocity.contents
      if currentVelocity->Vec2.len > 0.1 {
        updateCamera(currentVelocity)
        // Gradually reduce velocity (friction)
        cameraVelocity := currentVelocity->Vec2.scale(k->vec2(0.9, 0.9))
      }
    }
  })

  map
  ->Map.onKeyDown(key => {
    let currentCamPos = k->getCamPos

    let move = switch key {
    | Left => k->vec2(-speed, 0.)
    | Right => k->vec2(speed, 0.)
    | Up => k->vec2(0., -speed)
    | Down => k->vec2(0., speed)
    | _ => k->vec2(0., 0.)
    }
    let moveWithBounds = {
      let result = currentCamPos->Vec2.add(move)
      result.x = k->clampFloat(result.x, cameraBounds["x"]["min"], cameraBounds["x"]["max"])
      result.y = k->clampFloat(result.y, cameraBounds["y"]["min"], cameraBounds["y"]["max"])
      result
    }
    k->setCamPos(moveWithBounds)
  })
  ->ignore

  let _helpText = Text.make(
    ~x=15.,
    ~y=k->height - 30.,
    "Press arrow keys or touch to move the camera",
  )
}

k->loadSprite("bg", `${baseUrl}/sprites/middle-earth.webp`)

k->Context.onLoad(onLoad)
