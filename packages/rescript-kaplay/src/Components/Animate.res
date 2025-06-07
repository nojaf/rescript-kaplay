module Comp = (
  T: {
    type t
  },
) => {
  type animateCompOpt = {
    /** Changes the angle so it follows the motion, requires the rotate component */
    followMotion?: bool,
    /** The animation is added to the base values of pos, angle, scale and opacity instead of replacing them */
    relative?: bool,
  }

  type animation = {
    /** Pauses playing the animation */
    mutable paused: bool,
    /** Move the animation to a specific point in time */
    seek: float => unit,
    /** Returns the duration of the animation */
    duration: float,
  }

  type animateOpt = {
    /** Duration of the animation in seconds */
    duration: float,
    /** Loops, Default is undefined aka infinite */
    loops?: int,
    /** Behavior when reaching the end of the animation. Default is forward. */
    direction?: Types.timeDirection,
    /** Interpolation function. Default is linear interpolation */
    interpolation?: Types.interpolation,
    /** Timestamps in percent for the given keys, if omitted, keys are equally spaced. */
    timestamps?: array<float>,
    /** Easings for the given keys, if omitted, easing is used. */
    easing?: array<Types.easeFunc>,
  }

  /**
`animate(context, property name, keys, options)` to animate properties.
`keys` are generic to match the values of the property.

```ReScript
myGameObject->MyModule.animate(
  "pos",
  [k->Context.vec2(100., 200.), k->Context.vec2(200., 300.)],
  {duration: 1.},
)
```
   */
  @send
  external animate: (T.t, string, array<'key>, animateOpt) => unit = "animate"

  /**
`unanimate(context, property name)` to stop animating a property.
 */
  @send
  external unanimate: (T.t, string) => unit = "unanimate"

  @send
  external unanimateAll: T.t => unit = "unanimateAll"

  /**
Attaches an event handler which is called when all the animation channels have finished.
 */
  @send
  external onAnimateFinished: (T.t, unit => unit) => unit = "onAnimateFinished"

  /**
Attaches an event handler which is called when all the animation channels have finished.
 */
  @send
  external onAnimateFinishedWithController: (T.t, unit => unit) => KEventController.t =
    "onAnimateFinished"

  /**
`onAnimateChannelFinished(context, property name, (t) => unit)` attaches an event handler which is called when an animation channels has finished.
*/
  @send
  external onAnimateChannelFinished: (T.t, string => unit) => unit = "onAnimateChannelFinished"

  /**
`onAnimateChannelFinished(context, property name, (t) => unit)` attaches an event handler which is called when an animation channels has finished.
*/
  @send
  external onAnimateChannelFinishedWithController: (T.t, string => unit) => KEventController.t =
    "onAnimateChannelFinished"

  @get
  external getAnimation: T.t => animation = "animation"

  /**
`addAnimate(context, ~options=?) => comp` to animate properties.
 */
  @send
  external addAnimate: (Context.t, ~options: animateCompOpt=?) => Types.comp = "animate"
}
