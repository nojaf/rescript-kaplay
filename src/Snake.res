open Kaplay
open KaplayContext

// Constants
let gridSize = 20
let tileSize = 16.
let tileSizeVec2 = k->vec2(tileSize, tileSize)
let moveInterval = 0.22

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
  type t = {
    ...GameObj.t,
    mutable segments: array<GameObj.t>,
    mutable direction: Vec2.t,
    mutable timeSinceLastMove: float,
    mutable inputQueue: Queue.t<Vec2.t>,
  }

  external asGameObj: t => GameObj.t = "%identity"
  external asSnake: GameObj.t => t = "%identity"

  let addSegment = (self: GameObj.t, pos: Vec2.t, ~extraComponents: array<comp>=[]) => {
    if !(self->GameObj.has("snake")) {
      throw(Invalid_argument("Your gameObj does not have the snake component"))
    } else {
      let snake = self->asSnake
      let segment =
        self->GameObj.add(
          [
            k->Kaplay.posVec2(pos),
            k->Kaplay.rect(tileSize, tileSize),
            k->Kaplay.color(k->colorFromHex("#00d492")),
            k->Kaplay.outline(~width=1, ~color=k->colorFromHex("#000000")),
            k->Kaplay.area,
            tag("segment"),
            ...extraComponents,
          ],
        )

      Array.push(snake.segments, segment)
    }
  }

  let tryLastSegmentPos = (gameObj: GameObj.t) => {
    if !(gameObj->GameObj.has("snake")) {
      throw(Invalid_argument("Your gameObj does not have the snake component"))
    } else {
      gameObj->asSnake->(s => s.segments)->Array.last->Option.map(segment => segment.pos)
    }
  }

  let make = () => {
    customComponent({
      id: "snake",
      add: @this
      (snake: t) => {
        // Initialize the snake
        snake.segments = []
        snake.direction = k->Kaplay.vec2Right
        snake.timeSinceLastMove = 0.
        snake.inputQueue = Queue.make(2)

        snake
        ->asGameObj
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
              // We check if a previous key was pressed.
              let currentEffectiveDirection = switch snake.inputQueue->Queue.peek {
              | None => snake.direction
              | Some(lastDirection) => lastDirection
              }
              // Compare the current direction with the intended direction.
              // If a dot product is less than 0, the direction is reversed.
              let isReversal = intendedDirection->Vec2.dot(currentEffectiveDirection) < 0.

              if !isReversal {
                // If the direction is not reversed, we add the intended direction to the queue.
                snake.inputQueue->Queue.enqueue(intendedDirection)
              }
            }
          }
        })
        ->ignore

        // Add initial body segments
        for i in 0 to 2 {
          let pos = k->vec2(Int.toFloat(i) *. -tileSize, 0.)
          if i == 0 {
            snake->asGameObj->addSegment(pos, ~extraComponents=[tag("head")])
          } else {
            snake->asGameObj->addSegment(pos)
          }
        }
      },
      update: @this
      snake => {
        snake.timeSinceLastMove = snake.timeSinceLastMove + k->Kaplay.dt
        if snake.timeSinceLastMove > moveInterval {
          let previousPositions = snake.segments->Array.map(segment => segment.pos)

          // Move the head
          switch snake.segments[0] {
          | None => ()
          | Some(segment) =>
            // We check if there is a direction in the queue.
            switch snake.inputQueue->Queue.dequeue {
            | None => ()
            | Some(nextDirection) =>
              // If the direction is not reversed, we update the direction.
              // Why are we checking this twice? Didn't that happen in onKeyPressed?
              // There could be a delay between the key press and update.
              // We don't fully know what happened first.
              if nextDirection->Vec2.dot(snake.direction) >= 0. {
                snake.direction = nextDirection
              }
            }

            // Move the head
            segment.pos = Vec2.add(segment.pos, snake.direction->Vec2.scale(tileSizeVec2))
          }

          // Move the body segments
          for i in 1 to snake.segments->Array.length - 1 {
            // We move the body segments to the previous position of the next segment.
            switch (snake.segments[i], previousPositions[i - 1]) {
            | (Some(segment), Some(previousPos)) => segment.pos = previousPos
            | _ => ()
            }
          }

          // Reset the time since last move
          snake.timeSinceLastMove = 0.
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
        ],
      },
    },
  )

  let snake = grid->Level.spawn(
    [Snake.make()],
    k->vec2(
      //
      Int.toFloat(k->randi(10, gridSize - 10)),
      Int.toFloat(k->randi(10, gridSize - 10)),
    ),
  )

  addCoin(snake, grid)

  // grid->Level.spawn()
}
