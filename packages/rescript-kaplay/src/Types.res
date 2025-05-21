type comp

@unboxed
type key =
  | @as("left") Left
  | @as("right") Right
  | @as("up") Up
  | @as("down") Down
  | @as("space") Space
  | @as("enter") Enter

type color

type quad

type touch

/** Definition of a custom component */
type component<'t> = {
  id: string,
  update?: @this ('t => unit),
  require?: array<string>,
  add?: @this ('t => unit),
  draw?: @this ('t => unit),
  destroy?: @this ('t => unit),
  inspect?: @this ('t => unit),
}
