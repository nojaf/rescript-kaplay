open Kaplay
open GameContext

let sceneLoaded = () => {
  Wall.makeAll()
  let pikachu = Pokemon.make(
    k,
    ~pokemonId=25,
    ~level=12,
    ~move1=Thundershock.move,
    ~move2=QuickAttack.move,
    Team.Player,
  )
  Player.make(pikachu)
  let _pikachuHealthbar = Healthbar.make(pikachu)
  let charmander = Pokemon.make(k, ~pokemonId=4, ~level=5, ~move1=Ember.move, Team.Opponent)
  EnemyAI.make(k, ~enemy=charmander, ~player=pikachu)
  let _charmanderHealthbar = Healthbar.make(charmander)
}

let scene = () => {
  PkmnFont.load(k)
  Pokemon.load(k, 4)
  Pokemon.load(k, 25)
  Thundershock.load()
  Ember.load(k)
  QuickAttack.load(k)
  k->Context.onLoad(sceneLoaded)
}
