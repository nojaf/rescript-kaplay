open Kaplay
open KaplayContext

module type HomingType = {
  let homing: (Vec2.t, float, Vec2.t, GameObj.t, float, float) => comp
}

module Homing: HomingType = {
  type t = {
    ...GameObj.t,
    mutable homingTimer: float,
    mutable homingVelocity: Vec2.t,
  }

  include GameObjImpl({
    type t = t
  })

  let homing = (
    speed: Vec2.t,
    strength: float,
    from: Vec2.t,
    target: GameObj.t,
    timer: float,
    maxDistance: float,
  ): comp => {
    customComponent({
      id: "homing",
      add: @this
      (self: t) => {
        self.homingVelocity = target.pos->Vec2.sub(from)->Vec2.unit->Vec2.scale(speed)
        self.homingTimer = timer
      },
      update: @this
      (self: t) => {
        // If the timer is still running, update the velocity
        // The idea is that we don't home forever.
        if self.homingTimer > 0. {
          let toTarget = target.pos->Vec2.sub(self.pos)->Vec2.unit
          self.homingVelocity =
            self.homingVelocity->Vec2.lerp(toTarget->Vec2.scale(speed), strength)
          self.homingTimer = self.homingTimer - k->dt
        }

        self->move(self.homingVelocity)

        if self.pos->Vec2.dist(from) >= maxDistance {
          self->destroy
        }
      },
    })
  }
}

module type ShootingType = {
  let shoot: (Vec2.t, float) => comp
}

module Shooting: ShootingType = {
  let bubbleColors = [
    k->colorFromHex("#00bcff"),
    k->colorFromHex("#a2f4fd"),
    k->colorFromHex("#155dfc"),
  ]

  type t = {
    ...GameObj.t,
    mutable inSight: Map.t<int, GameObj.t>,
    mutable loopController: option<TimerController.t>,
  }

  include GameObjImpl({
    type t = t
  })

  let bulletSpeed = k->vec2(200., 200.)
  let homingStrength = 0.1
  let coolDown = 0.227

  let fireHomingBullet = (from, target: GameObj.t, maxDistance: float) => {
    let bulletColor = bubbleColors->Array.getUnsafe(k->randi(0, 2))
    let bullet =
      k->Kaplay.add([
        k->Kaplay.posVec2(from),
        k->area,
        tag("bullet"),
        k->z(0),
        k->circle(k->randi(4, 6), ~options={fill: true}),
        k->color(bulletColor),
        Homing.homing(bulletSpeed, homingStrength, from, target, 0.5, maxDistance),
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

  let shoot = (from: Vec2.t, maxDistance: float): comp => {
    customComponent({
      id: "shooting",
      add: @this
      (self: t) => {
        self.inSight = Map.make()

        // Keep track of who is in sight
        self
        ->onCollide("enemy", (e, _) => {
          self.inSight->Map.set(e.id, e)
        })
        ->ignore

        self
        ->onCollideEnd("enemy", e => {
          self.inSight->Map.delete(e.id)->ignore
        })
        ->ignore

        self.loopController = Some(
          k->loop(coolDown, () => {
            // Find the best suited enemy in sight to fire on.
            let next = self.inSight->Map.values->Iterator.next

            next.value->Option.forEach(enemy => {
              fireHomingBullet(from, enemy, maxDistance)
            })
          }),
        )
      },
      destroy: @this
      (self: t) => {
        self.loopController->Option.forEach(loopController => {
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
    k->pos(0., 400.),
    k->rect(k->width, 100.),
    k->color(k->colorFromHex("#cad5e2")),
  ])

  let tower = k->add([
    k->pos(k->width / 2., 320.),
    k->circle(30, ~options={fill: true}),
    k->color(k->colorFromHex("#e2e8f0")),
    k->body,
    tag("tower"),
    customComponent({
      id: "towerGuy",
      add: @this
      (tower: GameObj.t) => {
        tower
        ->GameObj.add([
          k->sprite("squirtle"),
          k->anchorCenter,
          k->color(k->colorFromHex("#00d3f2")),
          k->z(10),
        ])
        ->ignore
      },
    }),
  ])

  let _viewport = tower->GameObj.add([
    k->circle(200, ~options={fill: true}),
    k->color(k->colorFromHex("#D1FEB8")),
    k->opacity(0.),
    k->area(
      ~options={
        shape: circlePolygon(k->vec2(0., 0.), 200., ~segments=32),
      },
    ),
    Shooting.shoot(tower.pos, 200.),
  ])

  let regularColor = k->colorFromHex("#fe9441")

  k
  ->loop(1.0, () => {
    let _charmander = k->add([
      //
      k->sprite(
        "charmander",
        ~options={
          height: 36.,
          flipX: true,
        },
      ),
      k->color(regularColor),
      tag("enemy"),
      k->pos(50., 450.),
      k->area,
      k->anchorCenter,
      k->move(k->vec2(1., 0.), 100.),
      k->offscreen(~options={destroy: true}),
      k->health(3),
      customComponent({
        id: "hearts",
        add: @this
        charmander => {
          let hp = charmander->GameObj.hp
          for i in 1 to hp {
            charmander
            ->GameObj.add([
              k->pos(25. - Int.toFloat(i) * 15., -35.),
              k->sprite(
                "heart",
                ~options={
                  width: 10.,
                  height: 10.,
                },
              ),
              tag("solid-heart"),
            ])
            ->ignore
          }

          charmander
          ->GameObj.onHurt(_ => {
            let tc = k->tween(
              ~from=1.,
              ~to_=0.5,
              ~duration=0.1,
              ~setValue=opacity => {
                charmander.opacity = opacity
              },
              ~easeFunc=k.easings.linear,
            )

            tc->TweenController.onEnd(
              () => {
                k
                ->tween(
                  ~from=0.5,
                  ~to_=1.,
                  ~duration=0.1,
                  ~setValue=opacity => {
                    charmander.opacity = opacity
                  },
                  ~easeFunc=k.easings.linear,
                )
                ->ignore
              },
            )
          })
          ->ignore

          charmander
          ->GameObj.onDeath(() => {
            k->destroy(charmander)
          })
          ->ignore
        },
      }),
    ])
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
