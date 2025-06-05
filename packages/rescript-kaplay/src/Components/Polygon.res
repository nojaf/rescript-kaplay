module Comp = (
  T: {
    type t
  },
) => {
  @get
  external getPts: T.t => array<Vec2.t> = "pts"

  @set
  external setPts: (T.t, array<Vec2.t>) => unit = "pts"

  @get
  external getRadius: T.t => option<array<float>> = "radius"

  @set
  external setRadius: (T.t, array<float>) => unit = "radius"

  @get
  external getColors: T.t => option<array<Types.color>> = "colors"

  @set
  external setColors: (T.t, array<Types.color>) => unit = "colors"

  @get
  external getOpacities: T.t => option<array<float>> = "opacities"

  @set
  external setOpacities: (T.t, array<float>) => unit = "opacities"

  @get
  external getUv: T.t => option<array<Vec2.t>> = "uv"

  @set
  external setUv: (T.t, array<Vec2.t>) => unit = "uv"

  @get
  external getTexture: T.t => option<Texture.t> = "tex"

  @set
  external setTexture: (T.t, Texture.t) => unit = "tex"

  type polygonCompOpt = {
    /** If fill the shape with color (set this to false if you only want an outline) */
    fill?: bool,
    /** Manual triangulation. */
    indices?: array<float>,
    /** The center point of transformation in relation to the position. */
    offset?: Vec2.t,
    /** The radius of each corner. */
    radius?: array<float>,
    /** The color of each vertex. */
    color?: array<Types.color>,
    /** The uv of each vertex. */
    uv?: array<Vec2.t>,
    /** The texture if uv are supplied. */
    texture?: Texture.t,
    /** Triangulate concave polygons. */
    triangulate?: bool,
  }

  @send
  external addPolygon: (Context.t, array<Vec2.t>, ~options: polygonCompOpt=?) => Types.comp =
    "polygon"
}
