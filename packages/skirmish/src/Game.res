open Kaplay
open GameContext

let sceneLoaded = () => {
  let _pikachu = Pokemon.make(25)
}

let scene = () => {
  Pokemon.load(25)
  Thundershock.load()
  k->Context.onLoad(sceneLoaded)
}
