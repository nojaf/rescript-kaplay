open Kaplay

type state =
  | Thinking
  | Move
  | Attack
  | CoolDown(float)

@get
external getState: Pokemon.t => state = "state"

@set
external setState: (Pokemon.t, state) => unit = "state"

let directionToPlayer = (k: Context.t, enemy: Pokemon.t, player: Pokemon.t) => {
  let ew = 1.
  let ex = enemy->Pokemon.getPosX
  let px = player->Pokemon.getPosX
  let distance = px - ex
  switch distance {
  | distance if distance > ew => k->Context.vec2Right
  | distance if distance < -ew => k->Context.vec2Left
  | _ => k->Context.vec2Zero
  }
}

let addEnemyAI = (k: Context.t, player: Pokemon.t) => {
  let update =
    @this
    (self: Pokemon.t) => {
      switch self->getState {
      | Thinking => {
          let direction = directionToPlayer(k, self, player)
          if direction != k->Context.vec2Zero {
            self->setState(Move)
          } else {
            self->setState(Attack)
          }
        }
      | Move => {
          let direction = directionToPlayer(k, self, player)
          if direction == k->Context.vec2Zero {
            self->setState(Attack)
          } else {
            self->Pokemon.move(direction->Vec2.Unit.asWorld->Vec2.World.scaleWith(50.))
          }
        }
      | Attack => {
          Ember.cast(self)
          let t = k->Context.time + 2.0
          self->setState(CoolDown(t))
        }
      | CoolDown(t) =>
        if k->Context.time > t {
          self->setState(Thinking)
        }
      }
    }
  CustomComponent.make({
    id: "enemy-ai",
    update,
  })
}

let make = (k: Context.t, ~pokemonId: int, ~level: int, player: Pokemon.t): Pokemon.t => {
  let gameObj: Pokemon.t = Pokemon.make(k, ~pokemonId, ~level, Opponent)

  gameObj->setState(Thinking)

  gameObj->Pokemon.use(addEnemyAI(k, player))

  gameObj
}
