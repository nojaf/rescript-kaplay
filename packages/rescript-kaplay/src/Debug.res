type t = {
  /** Pause the whole game. */
  mutable paused: bool,
  /** Draw bounding boxes of all objects with `area()` component, hover to inspect their states. */
  mutable inspect: bool,
  /** Global time scale. */
  mutable timeScale: float,
  /** Show the debug log or not. */
  mutable showLog: bool,
}

/** Current frames per second. */
@send
external fps: t => int = "fps"

/** Total number of frames elapsed. */
@send
external numFrames: t => int = "numFrames"

/** Number of draw calls made last frame. */
@send
external drawCalls: t => int = "drawCalls"

/** Step to the next frame. Useful with pausing. */
@send
external stepFrame: t => unit = "stepFrame"

/** Clear the debug log. */
@send
external clearLog: t => unit = "clearLog"

/** Log some text to on screen debug log. */
@send
external log: (t, 't) => unit = "log"

/** Log an error message to on screen debug log. */
@send
external error: (t, 't) => unit = "error"

/** Get total number of objects. */
@send
external numObjects: t => int = "numObjects"
