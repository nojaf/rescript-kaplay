open Kaplay
open GameContext

let sceneLoaded = () => {
  let _pikachu = Pokemon.make(25, 12, Pokemon.Player)
  let _pikachuHealthbar = Healthbar.make(_pikachu)
  let _charmander = Pokemon.make(4, 5, Pokemon.Opponent)
  let _charmanderHealthbar = Healthbar.make(_charmander)
}

let scene = () => {
  Pokemon.load(4)
  Pokemon.load(25)
  Thundershock.load()
  Ember.load()
  k->Context.onLoad(sceneLoaded)
}
