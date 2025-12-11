open Kaplay

let name = "pkmn"

let load = (k: Context.t) => {
  k->Context.loadFont(name, "/pkmn.ttf")
}

let font = Context.makeDrawTextFontInfoFromString(name)
