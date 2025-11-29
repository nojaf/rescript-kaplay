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

// Velocity for momentum effect (world-space offset)
let cameraVelocity: ref<Vec2.World.t> = ref(k->vec2ZeroWorld)
let lastTouchStart: ref<Vec2.World.t> = ref(k->vec2ZeroWorld)
let isDragging = ref(false)

let updateCamera = (result: Vec2.World.t) => {
  let currentCamPos = k->getCamPos
  let moveWithBounds: Vec2.World.t = {
    let result = currentCamPos->Vec2.World.add(result)
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

  let touchStart = (pos: Vec2.Screen.t) => {
    lastTouchStart := Context.toWorld(k, pos)
    isDragging := true
    cameraVelocity := k->vec2ZeroWorld // Reset velocity
  }

  k->onTouchStart((pos, _touch) => {
    touchStart(pos)
  })

  let touchMove = (pos: Vec2.Screen.t) => {
    if isDragging.contents {
      // Convert screen position to world position
      let worldPos = Context.toWorld(k, pos)
      // Calculate world-space delta (displacement)
      let delta: Vec2.World.t = worldPos->Vec2.World.sub(lastTouchStart.contents)
      // Camera moves opposite to finger drag direction, scaled for responsiveness
      // Scaling preserves the World coordinate system type
      let sensitivity = k->Context.vec2World(-150., -100.)
      let worldDelta: Vec2.World.t = delta->Vec2.World.scale(sensitivity)
      cameraVelocity := worldDelta
      lastTouchStart := worldPos
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
      let currentVelocity: Vec2.World.t = cameraVelocity.contents
      if currentVelocity->Vec2.World.len > 0.1 {
        updateCamera(currentVelocity)
        // Gradually reduce velocity (friction)
        cameraVelocity := currentVelocity->Vec2.World.scaleWith(0.9)
      }
    }
  })

  map
  ->Map.onKeyDown(key => {
    let currentCamPos = k->getCamPos

    // Create world-space movement offset
    let move: Vec2.World.t = switch key {
    | Left => k->vec2World(-speed, 0.)
    | Right => k->vec2World(speed, 0.)
    | Up => k->vec2World(0., -speed)
    | Down => k->vec2World(0., speed)
    | _ => k->vec2ZeroWorld
    }
    let moveWithBounds: Vec2.World.t = {
      let result = currentCamPos->Vec2.World.add(move)
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
