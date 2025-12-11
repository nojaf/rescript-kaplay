open Kaplay
open GameContext

k->Context.scene("game", Game.scene)
k->Context.scene(GameOver.sceneName, GameOver.scene)
k->Context.go("game")
