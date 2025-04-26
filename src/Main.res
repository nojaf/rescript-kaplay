open Kaplay
open KaplayContext

k->scene("squartle", Squartle.scene)
k->scene("middle-earth", MiddleEarth.scene)
k->scene("path-finding", PathFinding.scene)
k->scene("sentry", Sentry.scene)
k->scene("tower", Tower.scene)
k->scene("snake", Snake.scene)

k->go("snake")
/*
type r = {
    x: option<int>
}

let r1 = { x: Some(1) }

let _ = switch r1 {
    | None => ()
    | 
}
*/
