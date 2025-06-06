module Comp = (
  T: {
    type t
  },
) => {
  /**
 Custom shader to manipulate sprite.
 */
  @send
  external addShader: (Context.t, string, ~uniform: unit => {..}=?) => Types.comp = "shader"
}
