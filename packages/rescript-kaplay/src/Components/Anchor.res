module Comp = (
  T: {
    type t
  },
) => {
  type anchor =
    | @as("topleft") TopLeft
    | @as("top") Top
    | @as("topright") TopRight
    | @as("left") Left
    | @as("center") Center
    | @as("right") Right
    | @as("botleft") BottomLeft
    | @as("bot") Bottom
    | @as("botright") BottomRight

  @send
  external addAnchor: (Context.t, anchor) => Types.comp = "anchor"

  @send
  external addAnchorCenter: (Context.t, @as("center") _) => Types.comp = "anchor"

  @send
  external addAnchorBottomLeft: (Context.t, @as("botleft") _) => Types.comp = "anchor"

  @send
  external addAnchorTop: (Context.t, @as("top") _) => Types.comp = "anchor"

  @send
  external addAnchorBottom: (Context.t, @as("bot") _) => Types.comp = "anchor"

  @send
  external addAnchorFromVec2: (Context.t, Vec2.t) => Types.comp = "anchor"
}
