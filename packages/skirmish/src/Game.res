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
    ~move3=Ember.move,
    ~move4=Ember.move,
    Team.Player,
  )
  Player.make(pikachu)
  let _pikachuHealthbar = Healthbar.make(pikachu)
  let enemy = Pokemon.make(k, ~pokemonId=4, ~level=5, Team.Opponent)
  // let _charmander = EnemyAI.make(k, ~pokemonId=4, ~level=5, pikachu)
  let _charmanderHealthbar = Healthbar.make(enemy)
  //let _temp = GenericMove.make(k, ~x=50., ~y=500., ~size=100., Player)
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
