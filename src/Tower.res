open Kaplay
open KaplayContext

module Homing = {
  type state = {
    mutable velocity: Vec2.t,
    mutable timer: float,
  }

  let homing = (
    speed: Vec2.t,
    strength: float,
    from: Vec2.t,
    target: GameObj.t,
    timer: float,
  ): comp => {
    let state = {
      velocity: target->GameObj.getPos->Vec2.sub(from)->Vec2.unit->Vec2.scale(speed),
      timer,
    }
    customComponent({
      id: "homing",
      update: @this
      self => {
        if state.timer > 0. {
          let toTarget = target->GameObj.getPos->Vec2.sub(self->GameObj.getPos)->Vec2.unit
          state.velocity = state.velocity->Vec2.lerp(toTarget->Vec2.scale(speed), strength)

          state.timer = state.timer - k->dt
        }

        self->GameObj.move(state.velocity)
      },
    })
  }
}

module Shooting = {
  type state = {
    coolDown: float,
    inSight: Map.t<int, GameObj.t>,
    mutable loopController: option<TimerController.t>,
  }

  let bulletSpeed = k->vec2(300., 300.)
  let homingStrength = 0.1

  let fireHomingBullet = (from, target: GameObj.t) => {
    let bullet =
      k->add([
        k->posVec2(from),
        k->area,
        tag("bullet"),
        k->circle(8, ~options={fill: true}),
        k->color(k->colorFromHex("#0D0D0D")),
        Homing.homing(bulletSpeed, homingStrength, from, target, 0.5),
      ])

    bullet
    ->GameObj.onCollide("enemy", (pkmn, _) => {
      bullet->GameObj.destroy
      pkmn->GameObj.hurt(1)
      pkmn
      ->GameObj.get("solid-heart")
      ->Array.at(0)
      ->Option.forEach(heart => {
        heart->GameObj.play("empty")
        heart->GameObj.untag("solid-heart")
      })
    })
    ->ignore
  }

  let shoot = (from: Vec2.t): comp => {
    let state = {
      coolDown: 0.3,
      inSight: Map.make(),
      loopController: None,
    }
    customComponent({
      id: "shooting",
      add: @this
      (self: GameObj.t) => {
        // Keep track of who is in sight
        self
        ->GameObj.onCollide("enemy", (e, _) => {
          state.inSight->Map.set(e.id, e)
        })
        ->ignore

        self
        ->GameObj.onCollideEnd("enemy", e => {
          state.inSight->Map.delete(e.id)->ignore
        })
        ->ignore

        state.loopController = Some(
          k->loop(state.coolDown, () => {
            // Find the best suited enemy in sight to fire on.
            let next = state.inSight->Map.values->Iterator.next

            next.value->Option.forEach(enemy => {
              fireHomingBullet(from, enemy)
            })
          }),
        )
      },
      destroy: @this
      _ => {
        state.loopController->Option.forEach(loopController => {
          loopController->TimerController.cancel
        })
      },
    })
  }
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

let onSceneLoad = () => {
  let _path = k->add([
    //
    k->pos(0, 400),
    k->rect(k->width, 100),
    k->color(k->colorFromHex("#D1E2F3")),
  ])

  let tower =
    k->add([
      k->pos(k->width / 2, 320),
      k->circle(50, ~options={fill: true}),
      k->color(k->colorFromHex("#D1FEB8")),
      k->body,
      tag("tower"),
    ])

  let _viewport = tower->GameObj.add([
    k->circle(200, ~options={fill: true}),
    k->color(k->colorFromHex("#D1FEB8")),
    k->opacity(0.2),
    k->area(
      ~options={
        shape: circlePolygon(k->vec2(0., 0.), 200., ~segments=32),
      },
    ),
    Shooting.shoot(tower->GameObj.getPos),
  ])

  let regularColor = k->colorFromHex("#fe9441")

  k
  ->loop(3., () => {
    let charmander = k->add([
      //
      k->sprite(
        "charmander",
        ~options={
          height: 36,
        },
      ),
      k->color(regularColor),
      tag("enemy"),
      k->pos(50, 450),
      k->area,
      k->anchorCenter,
      k->move(k->vec2(1., 0.), 100.),
      k->offscreen(~options={destroy: true}),
      k->health(3),
      customComponent({
        id: "hearts",
        add: @this
        charmander => {
          Console.log(`Charmander drawn with ${charmander->GameObj.hp->Int.toString} health`)

          let hp = charmander->GameObj.hp
          for i in 1 to hp {
            charmander
            ->GameObj.add([
              k->pos(30 - i * 15, -30),
              k->sprite(
                "heart",
                ~options={
                  width: 10,
                  height: 10,
                },
              ),
              tag("solid-heart"),
            ])
            ->ignore
          }
        },
      }),
    ])

    charmander
    ->GameObj.onDeath(() => {
      k->destroy(charmander)
    })
    ->ignore
  })
  ->ignore
}

let scene = (): unit => {
  k.debug->Debug.setInspect(true)
  k->loadSprite("charmander", "/sprites/charmander-rb.png")
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
