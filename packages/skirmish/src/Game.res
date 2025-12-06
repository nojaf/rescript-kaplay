open Kaplay
open GameContext

let sceneLoaded = () => {
  Wall.makeAll()
  let pikachu = Player.make(~pokemonId=25, ~level=12)
  let _pikachuHealthbar = Healthbar.make(pikachu)
  let _charmander = EnemyAI.make(k, ~pokemonId=4, ~level=5, pikachu)
  let _charmanderHealthbar = Healthbar.make(_charmander)
  let _temp = GenericMove.make(k, ~x=50., ~y=500., ~size=100., Player)
}

let scene = () => {
  Pokemon.load(k, 4)
  Pokemon.load(k, 25)
  Thundershock.load()
  Ember.load()
  k->Context.onLoad(sceneLoaded)
}
