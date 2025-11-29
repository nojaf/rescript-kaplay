open Kaplay
open Kaplay.Context

module Polygon = Kaplay.Math.Polygon

let k = Context.kaplay(~initOptions={width: 800, height: 400, scale, background: "#f0f9ff"})

module Tags = {
  let enemy = "enemy"
  let bubble = "bubble"
  let solidHeart = "solid-heart"
}

let circlePolygon = (center: Vec2.Local.t, radius: float, ~segments: int=32): Types.shape => {
  let points = Array.fromInitializer(~length=segments, idx => {
    let theta = Int.toFloat(idx) / Int.toFloat(segments) * 2. * Stdlib_Math.Constants.pi
    k->vec2World(
      //
      center.x + Stdlib_Math.cos(theta) * radius,
      center.y + Stdlib_Math.sin(theta) * radius,
    )
  })
  Polygon.make(k, points)->Polygon.asShape
}

let tryHeadOfMap = map => {
  map->Map.values->Iterator.find(_ => true)
}

module Path = {
  type t

  include Rect.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Color.Comp({type t = t})

  let make = () => {
    k->Context.add([
      k->addRect(k->width, 50.),
      k->addPos(0., 280.),
      k->addColor(k->Color.fromHex("#cad5e2")),
    ])
  }
}

module Heart = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Pos.Comp({type t = t})

  let make = (~x, ~y) => {
    [
      k->addSprite(
        "heart",
        ~options={
          width: 10.,
          height: 10.,
        },
      ),
      k->addPos(x, y),
      tag(Tags.solidHeart),
    ]
  }
}

module Charmander = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Sprite.Comp({type t = t})
  include Color.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Area.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Move.Comp({type t = t})
  include OffScreen.Comp({type t = t})
  include Health.Comp({type t = t})
  include Opacity.Comp({type t = t})

  let make = () => {
    let charmander = k->Context.add([
      k->addSprite(
        "charmander",
        ~options={
          height: 24.,
          flipX: true,
        },
      ),
      k->addColor(k->Color.fromHex("#fe9441")),
      k->addPos(0., 300.),
      k->addArea,
      k->addAnchorCenter,
      k->addMove(k->Context.vec2Right, 100.),
      k->addOffScreen(~options={destroy: true}),
      k->addHealth(3),
      tag(Tags.enemy),
    ])

    let hp = charmander->getHp
    for i in 1 to hp {
      charmander
      ->add(Heart.make(~x=25. - Int.toFloat(i) * 15., ~y=-35.))
      ->ignore
    }

    charmander->onHurt(_ => {
      let tc = k->tweenWithController(
        ~from=1.,
        ~to_=0.5,
        ~duration=0.1,
        ~setValue=opacity => {
          charmander->setOpacity(opacity)
        },
        ~easeFunc=k.easings.linear,
      )

      tc->TweenController.onEnd(() => {
        k
        ->tween(
          ~from=0.5,
          ~to_=1.,
          ~duration=0.1,
          ~setValue=v => charmander->setOpacity(v),
          ~easeFunc=k.easings.linear,
        )
        ->ignore
      })
    })

    charmander
    ->onDeath(() => {
      k->Context.destroy(charmander)
    })
    ->ignore

    charmander
  }
}

module Viewport = {
  type t = {inSight: Map.t<int, Charmander.t>}

  include Circle.Comp({type t = t})
  include Color.Comp({type t = t})
  include Opacity.Comp({type t = t})
  include Area.Comp({type t = t})

  external defaultState: t => Types.comp = "%identity"

  let make = () => {
    [
      k->addCircle(200., ~options={fill: true}),
      k->addColor(k->Color.fromHex("#D1FEB8")),
      k->addOpacity(0.2),
      k->addArea(~options={shape: circlePolygon(k->Context.vec2ZeroLocal, 200., ~segments=32)}),
      defaultState({inSight: Map.make()}),
    ]
  }
}

module Squirtle = {
  include Sprite.Comp({type t = t})
  include Anchor.Comp({type t = t})
  include Color.Comp({type t = t})
  include Z.Comp({type t = t})

  let make = () => {
    [
      k->addSprite("squirtle", ~options={height: 24., flipX: true}),
      k->addAnchorCenter,
      k->addColor(k->Color.fromHex("#00d3f2")),
      k->addZ(5),
    ]
  }
}

module Bubble = {
  type t = {
    mutable homingTimer: float,
    mutable homingVelocity: Vec2.World.t,
  }

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Area.Comp({type t = t})
  include Z.Comp({type t = t})
  include Circle.Comp({type t = t})
  include Color.Comp({type t = t})

  let bubbleColors = [
    k->Color.fromHex("#00bcff"),
    k->Color.fromHex("#a2f4fd"),
    k->Color.fromHex("#155dfc"),
  ]

  let make = (homingVelocity: Vec2.World.t, homingTimer: float) => {
    let bubbleColor = bubbleColors->Array.getUnsafe(k->randi(0, 2))
    [
      k->addPos(0., 0.),
      k->addColor(bubbleColor),
      tag(Tags.bubble),
      k->addZ(11),
      k->addCircle(k->randf(4., 6.), ~options={fill: true}),
      // default values for t, so it is at least defined
      Obj.magic({homingTimer, homingVelocity}),
      k->addArea,
    ]
  }
}

module Tower = {
  type t

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Circle.Comp({type t = t})
  include Color.Comp({type t = t})
  include Body.Comp({type t = t})

  let fireHomingBullet = (tower: t, viewport: Viewport.t, target: Charmander.t) => {
    let maxDistance = viewport->Viewport.getRadius
    let bulletSpeed = 500.
    let homingStrength = 0.1
    let homingVelocity: Vec2.World.t =
      target
      ->Charmander.worldPos
      ->Vec2.World.sub(tower->worldPos)
      ->Vec2.World.unit
      ->Vec2.World.scaleWith(bulletSpeed)
    let homingTimer = 0.2

    let bubble: Bubble.t = tower->addChild(Bubble.make(homingVelocity, homingTimer))

    bubble
    ->Bubble.onUpdate(() => {
      if bubble.homingTimer > 0. {
        let toTarget =
          target->Charmander.worldPos->Vec2.World.sub(bubble->Bubble.worldPos)->Vec2.World.unit
        bubble.homingVelocity =
          bubble.homingVelocity->Vec2.World.lerp(
            toTarget->Vec2.World.scaleWith(bulletSpeed),
            homingStrength,
          )
        bubble.homingTimer = bubble.homingTimer - k->dt
      }

      bubble->Bubble.move(bubble.homingVelocity)

      if bubble->Bubble.worldPos->Vec2.World.dist(tower->worldPos) >= maxDistance {
        bubble->Bubble.destroy
      }
    })
    ->ignore

    bubble->Bubble.onCollide(Tags.enemy, (enemy: Charmander.t, _) => {
      bubble->Bubble.destroy
      enemy->Charmander.setHp(enemy->Charmander.getHp - 1)
      switch enemy->Charmander.get(Tags.solidHeart)->Array.at(0) {
      | None => ()
      | Some(heart) => {
          heart->Heart.play("empty")
          heart->Heart.untag(Tags.solidHeart)
        }
      }
    })
  }

  let make = () => {
    let tower =
      k->Context.add([
        k->addPos(k->width / 2., 200.),
        k->addCircle(30., ~options={fill: true}),
        k->addColor(k->Color.fromHex("#cefafe")),
        k->addBody,
      ])

    let viewport: Viewport.t = tower->add(Viewport.make())

    viewport->Viewport.onCollide(Tags.enemy, (enemy: Charmander.t, _) => {
      viewport.inSight->Map.set(enemy->Charmander.getId, enemy)
    })

    viewport
    ->Viewport.onCollideEnd(Tags.enemy, (enemy: Charmander.t) => {
      viewport.inSight->Map.delete(enemy->Charmander.getId)->ignore
    })
    ->ignore

    let coolDown = 0.5
    k
    ->Context.loop(coolDown, () => {
      // Find the best suited enemy in sight to fire on.
      switch viewport.inSight->tryHeadOfMap {
      | None => ()
      | Some(enemy) => fireHomingBullet(tower, viewport, enemy)
      }
    })
    ->ignore

    tower
    ->add(Squirtle.make())
    ->ignore

    tower
  }
}

let onSceneLoad = () => {
  let _path = Path.make()
  let _tower = Tower.make()

  k
  ->loop(2.0, () => {
    let _charmander = Charmander.make()
  })
  ->ignore
}

k->loadSprite("charmander", `${baseUrl}/sprites/charmander-rb.png`)
k->loadSprite("squirtle", `${baseUrl}/sprites/squirtle-rb.png`)
k->loadSprite(
  "heart",
  `${baseUrl}/sprites/heart.png`,
  ~options={
    sliceX: 2,
    sliceY: 1,
    anims: dict{
      "solid": {from: 0, to: 0},
      "empty": {from: 1, to: 1},
    },
    anim: "solid",
  },
)

k->onLoad(onSceneLoad)
