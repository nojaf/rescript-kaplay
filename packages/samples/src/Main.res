open Kaplay.Context
open GameContext

k->scene("squirtle", Squirtle.scene)
k->scene("middle-earth", MiddleEarth.scene)
k->scene("path-finding", PathFinding.scene)
// k->scene("sentry", Sentry.scene)
// k->scene("tower", Tower.scene)

k->go("path-finding")
