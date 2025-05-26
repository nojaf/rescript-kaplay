module Comp = (
  T: {
    type t
  },
) => {
  @send
  external onObjectsSpotted: (T.t, array<'t> => unit) => KEventController.t = "onObjectsSpotted"

  type sentryOptions = {
    direction?: Vec2.t,
    fieldOfView?: float,
    lineOfSight?: bool,
    raycastExclude?: array<string>,
    checkFrequency?: float,
  }

  @send
  external addSentry: (Context.t, array<'t>, ~options: sentryOptions=?) => Types.comp = "sentry"
}
