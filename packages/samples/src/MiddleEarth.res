open Kaplay
open KaplayContext

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

module Map = {
  type t

  include PosComp({ type t = t })
  include SpriteComp({ type t = t })
  include AreaComp({ type t = t })

  let make = () => {
    k->Kaplay.add([
      addPos(k, 0., 0.),
      addSprite(k, "bg", ~options={
        width: mapWidth,
        height: mapHeight,
      }),
      addArea(k),
    ])
  }
}

let scene = () => {
  k->loadSprite("bg", "middle-earth.webp")

  let map = Map.make()

  k
  ->onTouchStart((pos, _touch) => {
    lastTouchStart := pos
    isDragging := true
    cameraVelocity := zeroVector // Reset velocity
  })
  ->ignore

  // On touch move (update velocity)
  k
  ->onTouchMove((pos, _touch) => {
    if isDragging.contents {
      let delta = pos->Vec2.sub(lastTouchStart.contents)
      cameraVelocity := delta->Vec2.scale(k->vec2(-150., -100.)) // Scale for responsiveness
      lastTouchStart := pos
    }
  })
  ->ignore

  // On touch end (apply momentum)
  k
  ->onTouchEnd((_, _touch) => {
    isDragging := false
  })
  ->ignore

  // Update camera position every frame (momentum effect)
  k
  ->onUpdate(() => {
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
  ->ignore

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
}
