open Kaplay
open KaplayContext

// Constants
let gridSize = 10
let tileSize = 16.
let tileSizeVec2 = k->vec2(tileSize, tileSize)
let moveInterval = 0.50
let score = ref(0)

module Queue = {
  type t<'item> = {mutable items: array<'item>, maxSize: int}

  let make = (maxSize: int) => {
    {items: [], maxSize}
  }

  let enqueue = (t: t<'item>, item: 'item) => {
    t.items->Array.push(item)
    if t.items->Array.length > t.maxSize {
      t.items->Array.shift->ignore
    }
  }

  let dequeue = (t: t<'item>) => {
    t.items->Array.shift
  }

  let peek = (t: t<'item>) => {
    t.items[0]
  }
}

module Snake = {
  type state = {
    mutable segments: array<GameObj.t>,
    mutable direction: Vec2.t,
    mutable timeSinceLastMove: float,
    mutable inputQueue: Queue.t<Vec2.t>,
    mutable isDead: bool,
  }

  @get
  external getSnakeState: GameObj.t => state = "snake"

  @set
  external setSnakeState: (GameObj.t, state) => unit = "snake"

  let addSegment = (self: GameObj.t, pos: Vec2.t, ~isHead: bool=false) => {
    if !(self->GameObj.has("snake")) {
      throw(Invalid_argument("Your gameObj does not have the snake component"))
    } else {
      let state = self->getSnakeState
      let segment =
        self->GameObj.add(
          [
            k->posVec2(pos),
            k->rect(tileSize, tileSize),
            k->color(k->colorFromHex("#00d492")),
            k->outline(~width=1, ~color=k->colorFromHex("#000000")),
            k->area,
            tag("segment"),
            ...isHead ? [tag("head")] : [],
          ],
        )

      Array.push(state.segments, segment)
    }
  }

  let tryLastSegmentPos = (gameObj: GameObj.t) => {
    if !(gameObj->GameObj.has("snake")) {
      throw(Invalid_argument("Your gameObj does not have the snake component"))
    } else {
      gameObj->getSnakeState->(s => s.segments)->Array.last->Option.map(segment => segment.pos)
    }
  }

  let make = () => {
    customComponent({
      id: "snake",
      add: @this
      (snake: GameObj.t) => {
        // Initialize the snake
        snake->setSnakeState({
          segments: [],
          direction: k->Kaplay.vec2Right,
          timeSinceLastMove: 0.,
          inputQueue: Queue.make(2),
          isDead: false,
        })

        snake
        ->GameObj.onKeyPress(key => {
          // The arrow keys are used to control the snake
          let intendedDirection = switch key {
          | Up => Some(k->Kaplay.vec2Up)
          | Down => Some(k->Kaplay.vec2Down)
          | Left => Some(k->Kaplay.vec2Left)
          | Right => Some(k->Kaplay.vec2Right)
          | _ => None
          }

          switch intendedDirection {
          | None => ()
          | Some(intendedDirection) => {
              let state = snake->getSnakeState
              // We check if a previous key was pressed.
              let currentEffectiveDirection = switch state.inputQueue->Queue.peek {
              | None => state.direction
              | Some(lastDirection) => lastDirection
              }
              // Compare the current direction with the intended direction.
              // If a dot product is less than 0, the direction is reversed.
              let isReversal = intendedDirection->Vec2.dot(currentEffectiveDirection) < 0.

              if !isReversal {
                // If the direction is not reversed, we add the intended direction to the queue.
                state.inputQueue->Queue.enqueue(intendedDirection)
              }
            }
          }
        })
        ->ignore

        // Add initial body segments
        for i in 0 to 2 {
          let pos = k->vec2(Int.toFloat(i) *. -tileSize, 0.)
          snake->addSegment(pos, ~isHead=i == 0)
        }
      },
      update: @this
      (snake: GameObj.t) => {
        let state = snake->getSnakeState

        // Immediately stop processing if the snake is dead
        if !state.isDead {
          state.timeSinceLastMove = state.timeSinceLastMove + k->Kaplay.dt
          if state.timeSinceLastMove > moveInterval {
            // Get current head position and calculate potential next position
            switch state.segments[0] {
            | None => () // Should not happen if snake has segments
            | Some(headSegment) =>
              // Check if input queue has a new direction
              switch state.inputQueue->Queue.dequeue {
              | None => ()
              | Some(nextDirection) =>
                if nextDirection->Vec2.dot(state.direction) >= 0. {
                  state.direction = nextDirection
                }
              }

              let nextPos = Vec2.add(
                headSegment->GameObj.worldPos,
                state.direction->Vec2.scale(tileSizeVec2),
              )

              let walls = k->getGameObjects(
                "wall",
                ~options={
                  recursive: true,
                },
              )

              let willCollide = walls->Array.some(wall => wall->GameObj.hasPoint(nextPos))

              if willCollide {
                state.isDead = true
              } else {
                // No collision predicted, proceed with movement
                let previousPositions = state.segments->Array.map(segment => segment.pos)
                // Move the head with the new world position
                headSegment->GameObj.setWorldPos(nextPos)

                // Move the body segments
                for i in 1 to state.segments->Array.length - 1 {
                  switch (state.segments[i], previousPositions[i - 1]) {
                  | (Some(segment), Some(previousPos)) => segment.pos = previousPos
                  | _ => ()
                  }
                }

                // Reset the time since last move
                state.timeSinceLastMove = 0.
              }
            }
          }
        }
      },
    })
  }
}

let rec addCoin = (snake: GameObj.t, grid: Level.t) => {
  // We find a random position that is not occupied by the snake
  let randomPosition =
    k->vec2(Int.toFloat(k->randi(1, gridSize - 1)), Int.toFloat(k->randi(1, gridSize - 1)))

  if (
    Array.every(snake->GameObj.get("segment"), segment =>
      !(segment->GameObj.hasPoint(randomPosition))
    )
  ) {
    // We spawn the coin if none of the segments are on the random position.
    let coin = grid->Level.spawn(
      [
        //  Tweak the surface area so that the coin is only hit if the snake's head is on top of it.
        k->area(
          ~options={
            scale: 0.5,
            offset: k->vec2(tileSize / 4., tileSize / 4.),
          },
        ),
        tag("coin"),
        k->rect(tileSize, tileSize),
        k->color(k->colorFromHex("#ffd700")),
        k->outline(~width=1, ~color=k->colorFromHex("#000000")),
        k->z(-1),
      ],
      randomPosition,
    )

    coin
    ->GameObj.onCollideEnd("head", _segment => {
      coin->GameObj.destroy

      switch snake->Snake.tryLastSegmentPos {
      | None => ()
      | Some(lastSegmentPos) => snake->Snake.addSegment(lastSegmentPos)
      }

      addCoin(snake, grid)
    })
    ->ignore
  } else {
    addCoin(snake, grid)
  }
}

let scene = () => {
  let grid = k->addLevel(
    [
      String.repeat("x", gridSize),
      ...Array.fromInitializer(~length=gridSize - 2, _ =>
        "x" ++ String.repeat(" ", gridSize - 2) ++ "x"
      ),
      String.repeat("x", gridSize),
    ],
    {
      tileWidth: tileSize,
      tileHeight: tileSize,
      tiles: dict{
        "x": () => [
          //
          k->area,
          k->rect(tileSize, tileSize),
          k->color(k->colorFromHex("#a684ff")),
          tag("wall"),
          k->outline(~width=1, ~color=k->colorFromHex("#000000")),
          k->z(1),
        ],
      },
    },
  )

  let snake = grid->Level.spawn(
    [Snake.make()],
    k->vec2(
      // Spawn within the inner grid boundaries (1 to gridSize - 2)
      Int.toFloat(k->randi(1, gridSize - 2)),
      Int.toFloat(k->randi(1, gridSize - 2)),
    ),
  )

  addCoin(snake, grid)

  // grid->Level.spawn()
}
