open Kaplay
open KaplayContext

k->scene("squartle", Squartle.scene)
k->scene("middle-earth", MiddleEarth.scene)

k->go("middle-earth", ~data=())
