open Kaplay
open KaplayContext

module Homing = {
  @editor.completeFrom("Homing")
  type t = GameObj.t

  let homing = (velocity: Vec2.t, timer: float): comp => {
    Obj.magic({"homingVelocity": velocity, "homingTimer": timer})
  }

  @set
  external setHomingVelocity: (t, Vec2.t) => unit = "homingVelocity"

  @get
  external getHomingVelocity: t => Vec2.t = "homingVelocity"

  @get
  external getHomingTimer: t => float = "homingTimer"

  @set
  external setHomingTimer: (t, float) => unit = "homingTimer"
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

let scene = (): unit => {
  k.debug->Debug.setInspect(true)
  k->loadSprite("charmander", "/sprites/charmander-rb.png")

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

  let viewport = tower->GameObj.add([
    k->circle(200, ~options={fill: true}),
    k->color(k->colorFromHex("#D1FEB8")),
    k->opacity(0.2),
    k->area(
      ~options={
        shape: circlePolygon(k->vec2(0., 0.), 200., ~segments=32),
      },
    ),
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
      tag("pkmn"),
      k->pos(50, 450),
      k->area,
      k->anchorCenter,
      k->move(k->vec2(1., 0.), 100.),
      k->offscreen(~options={destroy: true}),
      k->health(3),
    ])

    charmander
    ->GameObj.onDeath(() => {
      k->destroy(charmander)
    })
    ->ignore
  })
  ->ignore

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
        Homing.homing(
          target->GameObj.getPos->Vec2.sub(from)->Vec2.unit->Vec2.scale(bulletSpeed),
          0.5,
        ),
      ])

    bullet
    ->GameObj.onUpdate(() => {
      if bullet->Homing.getHomingTimer > 0. {
        let toTarget = target->GameObj.getPos->Vec2.sub(bullet->GameObj.getPos)->Vec2.unit
        bullet->Homing.setHomingVelocity(
          bullet
          ->Homing.getHomingVelocity
          ->Vec2.lerp(toTarget->Vec2.scale(bulletSpeed), homingStrength),
        )
        bullet->Homing.setHomingTimer(bullet->Homing.getHomingTimer - k->dt)
      }

      bullet->GameObj.move(bullet->Homing.getHomingVelocity)
    })
    ->ignore

    bullet
    ->GameObj.onCollide("pkmn", (pkmn, _) => {
      k.debug->Debug.log("bullet hit pkmn")
      pkmn->GameObj.setColor(k->colorFromHex("#000000"))
      bullet->GameObj.destroy
      pkmn->GameObj.hurt(1)
    })
    ->ignore
  }

  viewport
  ->GameObj.onCollide("pkmn", (pkmn, _) => {
    pkmn->GameObj.setColor(k->colorFromHex("#FF0000"))
    fireHomingBullet(tower->GameObj.getPos, pkmn)
  })
  ->ignore

  viewport
  ->GameObj.onCollideEnd("pkmn", pkmn => {
    pkmn->GameObj.setColor(regularColor)
  })
  ->ignore
}
