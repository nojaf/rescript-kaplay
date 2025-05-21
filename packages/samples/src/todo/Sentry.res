// open Kaplay
// open KaplayContext

// let scene = () => {
//   k->loadSprite("squirtle", "/sprites/squirtle-rb.png")
//   k->loadSprite("flareon", "/sprites/flareon-rb.png")

//   let squirtle =
//     k->add([
//       k->sprite("squirtle"),
//       k->pos(100., 100.),
//       k->anchorCenter,
//       k->color(k->colorFromHex("#ADD8E6")),
//       k->area,
//       k->body,
//     ])

//   let flareon = k->add([
//     k->sprite("flareon"),
//     k->pos(400., 400.),
//     k->anchorCenter,
//     k->color(k->colorFromHex("#FF746C")),
//     k->sentry(
//       [squirtle],
//       ~options={
//         fieldOfView: 45.,
//         direction: k->vec2(0., 0.),
//         lineOfSight: true,
//         checkFrequency: 0.200,
//       },
//     ),
//   ])

//   let _wall =
//     k->add([
//       k->rect(20., 700.),
//       k->pos(300., 200.),
//       k->anchorCenter,
//       k->color(k->colorFromHex("#D1E2F3")),
//       k->area,
//       k->body(~options={isStatic: true}),
//     ])

//   k
//   ->add([
//     //
//     k->pos(340., 460.),
//     k->text("Move underneath Flareon to be spotted", ~options={size: 20.}),
//   ])
//   ->ignore

//   flareon
//   ->GameObj.onObjectsSpotted(spotted => {
//     k.debug->Debug.log(`Spotted squirtle: ${spotted->Array.length->Int.toString}`)
//   })
//   ->ignore

//   squirtle
//   ->GameObj.onKeyDown(key => {
//     switch key {
//     | Left => squirtle->GameObj.move(k->vec2(-400., 0.))
//     | Right => squirtle->GameObj.move(k->vec2(400., 0.))
//     | Up => squirtle->GameObj.move(k->vec2(0., -400.))
//     | Down => squirtle->GameObj.move(k->vec2(0., 400.))
//     | _ => ()
//     }
//   })
//   ->ignore
// }
