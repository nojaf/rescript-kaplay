open Pixi

type fish = {
  ...Sprite.t,
  mutable direction: float,
  mutable speed: float,
  mutable turnSpeed: float,
}

external fromSprite: Sprite.t => fish = "%identity"
external fromContainer: Container.t => fish = "%identity"
external asSprite: fish => Sprite.t = "%identity"
external asContainer: fish => Container.t = "%identity"

let addFishes = (app: Application.t) => {
  let fishContainer = Container.make()
  fishContainer.label = "fish_container"
  app.stage->Container.addChild([fishContainer])

  let fishCount = 5
  let fishAssets = ["fish1", "fish2", "fish3", "fish4", "fish5"]
  let assetsLength = Array.length(fishAssets)

  Array.make(~length=fishCount, 0)
  ->Array.flatMapWithIndex((_, idx) => {
    switch Array.at(fishAssets, mod(idx, assetsLength)) {
    | None => []
    | Some(fishAsset) => {
        let fish = Sprite.from(fishAsset)->fromSprite
        fish.anchor->ObservablePoint.setBoth(0.5)

        // Custom properties
        fish.direction = Math.random() *. Math.Constants.pi *. 2.
        fish.speed = 2. +. Math.random() *. 2.
        fish.turnSpeed = Math.random() -. 0.8

        // Randomly position the fish sprite around the stage.
        fish.x = Math.random() *. app.screen.width
        fish.y = Math.random() *. app.screen.height

        // Randomly scale the fish sprite to create some variety.
        fish.scale->ObservablePoint.setBoth(0.5 + Math.random() * 0.2)

        [asContainer(fish)]
      }
    }
  })
  ->(items => Container.addChild(fishContainer, items))
}

let animateFishes = (app: Application.t, fishes, _time: Ticker.t) => {
  // Define the padding around the stage where fishes are considered out of sight.
  let stagePadding = 100.
  let boundWidth = app.screen.width +. stagePadding *. 2.
  let boundHeight = app.screen.height +. stagePadding *. 2.

  // Iterate through each fish sprite.
  fishes->Array.forEach(fish => {
    // Animate the fish movement direction according to the turn speed.
    fish.direction = fish.direction + fish.turnSpeed * 0.01

    // Animate the fish position according to the direction and speed.
    fish.x = fish.x + Math.sin(fish.direction) * fish.speed
    fish.y = fish.y + Math.cos(fish.direction) * fish.speed

    // Apply the fish rotation according to the direction.
    fish.rotation = -fish.direction - Math.Constants.pi /. 2.

    // Wrap the fish position when it goes out of bounds.
    if fish.x < -stagePadding {
      fish.x = fish.x + boundWidth
    }
    if fish.x > app.screen.width + stagePadding {
      fish.x = fish.x - boundWidth
    }
    if fish.y < -stagePadding {
      fish.y = fish.y + boundHeight
    }
    if fish.y > app.screen.height + stagePadding {
      fish.y = fish.y - boundHeight
    }
  })
}
