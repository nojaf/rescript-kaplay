open Kaplay

@unboxed
type t = | @as(true) Player | @as(false) Opponent

let player = "player"
let opponent = "opponent"

let playerTagComponent = Context.tag(player)
let opponentTagComponent = Context.tag(opponent)

let getTagComponent = (team: t) => {
  team == Player ? playerTagComponent : opponentTagComponent
}
