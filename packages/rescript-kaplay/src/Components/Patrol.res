module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getWaypoints: T.t => option<array<Vec2.World.t>> = "waypoints"

  @set
  external setWaypoints: (T.t, array<Vec2.World.t>) => unit = "waypoints"

  @get
  external getPatrolSpeed: T.t => float = "patrolSpeed"

  @set
  external setPatrolSpeed: (T.t, float) => unit = "patrolSpeed"

  @get
  external getNextLocation: T.t => option<Vec2.World.t> = "nextLocation"

  @set
  external setNextLocation: (T.t, Vec2.World.t) => unit = "nextLocation"

  /**
`onPatrolFinished(context, (t) => unit)`

Attaches an event handler which is called when using "stop" and the end of the path is reached.
*/
  @send
  external onPatrolFinished: (T.t, T.t => unit) => unit = "onPatrolFinished"

  /**
`onPatrolFinished(context, (t) => unit)`

Attaches an event handler which is called when using "stop" and the end of the path is reached.
*/
  @send
  external onPatrolFinishedWithController: (T.t, T.t => unit) => KEventController.t =
    "onPatrolFinished"

  type endBehavior =
    | @as("loop") Loop
    | @as("ping-pong") PingPong
    | @as("stop") Stop

  type patrolCompOptions = {
    waypoints?: array<Vec2.World.t>,
    speed?: float,
    endBehavior?: endBehavior,
  }

  /**
Requires a `Pos` component.
 */
  @send
  external addPatrol: (Context.t, patrolCompOptions) => Types.comp = "patrol"
}
