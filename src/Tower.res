open Kaplay
open KaplayContext

let scene = (): unit => {
  k->loadSprite("charmander", "/sprites/charmander-rb.png")

  let _ = k->add([
    //
    k->pos(0, 400),
    k->rect(k->width, 100),
    k->color(k->colorFromHex("#D1E2F3")),
  ])

  let tower =
    k->add([
      k->pos(k->width / 2, 350),
      k->circle(30, ~options={fill: true}),
      k->color(k->colorFromHex("#D1FEB8")),
      k->area,
      k->body,
      tag("tower"),
    ])

  let viewport =
    tower->GameObj.add([
      k->circle(200, ~options={fill: true}),
      k->color(k->colorFromHex("#D1FEB8")),
      k->opacity(0.2),
      k->area,
    ])

  let regularColor = k->colorFromHex("#fe9441")

  k
  ->loop(3., () => {
    k
    ->add([
      //
      k->sprite(
        "charmander",
        ~options={
          height: 36,
        },
      ),
      k->color(regularColor),
      tag("pkmn"),
      k->pos(25, 450),
      k->area,
      k->anchorCenter,
      k->move(k->vec2(1., 0.), 200.),
      k->offscreen(~options={destroy: true}),
    ])
    ->ignore
  })
  ->ignore

  viewport
  ->GameObj.onCollide("pkmn", (pkmn, _) => {
    k.debug->Debug.log("pkmn in viewport")
    pkmn->GameObj.setColor(k->colorFromHex("#FF0000"))
  })
  ->ignore

  viewport
  ->GameObj.onCollideEnd("pkmn", pkmn => {
    k.debug->Debug.log("pkmn out of viewport")
    pkmn->GameObj.setColor(regularColor)
  })
  ->ignore
}
