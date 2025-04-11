open Kaplay

let k = kaplay()

k->loadSprite(
  "squartle",
  "sprites/squirtle.jpeg",
  ~options={
    sliceX: 4,
    sliceY: 1,
  },
)

let squartle = k->add([
  //
  k->pos(10, 20),
  k->sprite("squartle"),
])

let speed = 200

k
->onKeyDown(key => {
  k.debug->Debug.log((key :> string))

  switch key {
  | Left => squartle->GameObj.move(-speed, 0)
  | Right => squartle->GameObj.move(speed, 0)
  | Up => squartle->GameObj.move(0, -speed)
  | Down => squartle->GameObj.move(0, speed)
  | _ => ()
  }
})
->ignore
