open Kaplay
open GameContext

let sceneLoaded = () => {
  let pikachu = Player.make(~pokemonId=25, ~level=12)
  let _pikachuHealthbar = Healthbar.make(pikachu)
  let _charmander = EnemyAI.make(~pokemonId=4, ~level=5, pikachu)
  let _charmanderHealthbar = Healthbar.make(_charmander)
}

let scene = () => {
  Pokemon.load(4)
  Pokemon.load(25)
  Thundershock.load()
  Ember.load()
  k->Context.onLoad(sceneLoaded)
}
