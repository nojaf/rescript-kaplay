open Kaplay
open Kaplay.Context
open GameContext

module Tags = {
  let enemy = "enemy"
  let bubble = "bubble"
  let solidHeart = "solid-heart"
}

let circlePolygon = (center: Vec2.t, radius: float, ~segments: int=32): Kaplay.Math.Shape.t => {
  let points = Array.fromInitializer(~length=segments, idx => {
    let theta = Int.toFloat(idx) / Int.toFloat(segments) * 2. * Stdlib_Math.Constants.pi
    k->vec2(
      //
      center.x + Stdlib_Math.cos(theta) * radius,
      center.y + Stdlib_Math.sin(theta) * radius,
    )
  })
  mathPolygon(k, points)
}

@send
external iteratorFind: (Iterator.t<'t>, 't => bool) => option<'t> = "find"

let tryHeadOfMap = map => {
  map->Map.values->iteratorFind(_ => true)
}

module Path = {
  type t

  include Rect.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Color.Comp({type t = t})

  let make = () => {
    k->Context.add([
      k->addRect(k->width, 100.),
      k->addPos(0., 400.),
      k->addColor(k->colorFromHex("#cad5e2")),
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
          height: 36.,
          flipX: true,
        },
      ),
      k->addColor(k->colorFromHex("#fe9441")),
      k->addPos(50., 450.),
      k->addArea,
      k->addAnchorCenter,
      k->addMove(k->vec2(1., 0.), 100.),
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
      let tc = k->tween(
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
      k->addColor(k->colorFromHex("#D1FEB8")),
      k->addOpacity(0.2),
      k->addArea(~options={shape: circlePolygon(k->vec2(0., 0.), 200., ~segments=32)}),
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
      k->addSprite("squirtle", ~options={height: 36., flipX: true}),
      k->addAnchorCenter,
      k->addColor(k->colorFromHex("#00d3f2")),
      k->addZ(5),
    ]
  }
}

module Bubble = {
  type t = {
    mutable homingTimer: float,
    mutable homingVelocity: Vec2.t,
  }

  include GameObjRaw.Comp({type t = t})
  include Pos.Comp({type t = t})
  include Area.Comp({type t = t})
  include Z.Comp({type t = t})
  include Circle.Comp({type t = t})
  include Color.Comp({type t = t})

  let bubbleColors = [
    k->colorFromHex("#00bcff"),
    k->colorFromHex("#a2f4fd"),
    k->colorFromHex("#155dfc"),
  ]

  let make = (homingVelocity: Vec2.t, homingTimer: float) => {
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
    let bulletSpeed = k->vec2FromXY(500.)
    let homingStrength = 0.1
    let homingVelocity =
      target->Charmander.worldPos->Vec2.sub(tower->worldPos)->Vec2.unit->Vec2.scale(bulletSpeed)
    let homingTimer = 0.2

    let bubble: Bubble.t = tower->add(Bubble.make(homingVelocity, homingTimer))

    bubble
    ->Bubble.onUpdate(() => {
      if bubble.homingTimer > 0. {
        let toTarget = target->Charmander.worldPos->Vec2.sub(bubble->Bubble.worldPos)->Vec2.unit
        bubble.homingVelocity =
          bubble.homingVelocity->Vec2.lerp(toTarget->Vec2.scale(bulletSpeed), homingStrength)
        bubble.homingTimer = bubble.homingTimer - k->dt
      }

      bubble->Bubble.move(bubble.homingVelocity)

      if bubble->Bubble.worldPos->Vec2.dist(tower->worldPos) >= maxDistance {
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
        k->addPos(k->width / 2., 320.),
        k->addCircle(30., ~options={fill: true}),
        k->addColor(k->colorFromHex("#cefafe")),
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

let scene = (): unit => {
  //k.debug->Debug.setInspect(true)
  k->loadSprite("charmander", "/sprites/charmander-rb.png")
  k->loadSprite("squirtle", "/sprites/squirtle-rb.png")
  k->loadSprite(
    "heart",
    "/sprites/heart.png",
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
}
