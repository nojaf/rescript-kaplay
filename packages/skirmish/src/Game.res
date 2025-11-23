open Kaplay
open GameContext

let sceneLoaded = () => {
    let pikachu = Pokemon.make(25)
    ()
}

let scene = () => {
    Pokemon.load(25)
    k->Context.onLoad(sceneLoaded)
}
