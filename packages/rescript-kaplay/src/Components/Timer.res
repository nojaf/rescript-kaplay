module Comp = (
  T: {
    type t
  },
) => {
  /** The maximum number of loops per frame allowed, to keep loops with sub-frame intervals from freezing the game. */
  @get
  external getMaxLoopsPerFrame: T.t => float = "maxLoopsPerFrame"

  /** The maximum number of loops per frame allowed, to keep loops with sub-frame intervals from freezing the game. */
  @set
  external setMaxLoopsPerFrame: (T.t, float) => unit = "maxLoopsPerFrame"

  /**
`wait(t, duration in seconds, action?)`
Run the callback after n seconds.
 */
  @send
  external wait: (T.t, float, ~action: unit => unit) => unit = "wait"

  /** 
`wait(t, duration in seconds, action?)`
Run the callback after n seconds.
 */
  @send
  external waitWithController: (T.t, float, ~action: unit => unit) => TimerController.t = "wait"

  /**
Run the callback every n seconds. 
If waitFirst is false (the default), the function will be called once on the very next frame, and then loop like normal.
 */
  @send
  external loop: (T.t, float, unit => unit, ~maxLoops: int=?, ~waitFirst: bool=?) => unit = "loop"

  /**
Run the callback every n seconds. 
If waitFirst is false (the default), the function will be called once on the very next frame, and then loop like normal.
 */
  @send
  external loopWithController: (
    T.t,
    float,
    unit => unit,
    ~maxLoops: int=?,
    ~waitFirst: bool=?,
  ) => TimerController.t = "loop"

  /** 
`tween(context, from, to, duration in seconds, setValue, easeFunc=?) => unit` 

Useful to change a property of a Game Object over time.
```ReScript
k
->Context.tween(
  ~from=-15.,
  ~to_=0.,
  ~duration=0.5,
  ~setValue=Bird.setAngle(bird, ...),
)
```
*/
  @send
  external tween: (
    T.t,
    ~from: 'v,
    ~to_: 'v,
    ~duration: float,
    ~setValue: 'v => unit,
    ~easeFunc: Types.easeFunc=?,
  ) => unit = "tween"

  /** 
`tween(context, from, to, duration in seconds, setValue, easeFunc=?) => TweenController.t` 

Useful to change a property of a Game Object over time.
```ReScript
k
->Context.tween(
  ~from=-15.,
  ~to_=0.,
  ~duration=0.5,
  ~setValue=Bird.setAngle(bird, ...),
)
```
*/
  @send
  external tweenWithController: (
    T.t,
    ~from: 'v,
    ~to_: 'v,
    ~duration: float,
    ~setValue: 'v => unit,
    ~easeFunc: Types.easeFunc=?,
  ) => TweenController.t = "tween"

  /** 
`addTimer(context, maxLoopsPerFrame: float=?)` => Types.comp
Enable timer related functions like wait(), loop(), tween() on the game object. 
*/
  @send
  external addTimer: (Context.t, ~maxLoopsPerFrame: float=?) => Types.comp = "timer"
}
