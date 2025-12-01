open Kaplay

/***
 * Attack component provides a common mechanism to declare where an attack is physically located
 * in world space. This is used for querying attacks (e.g., in rule systems for AI decision-making)
 * and spatial queries.
 *
 * **Why this exists instead of using Area component:**
 * - Kaplay's `Area` component only supports **convex polygons** for collision detection.
 * - Attacks with concave shapes (e.g., zigzag lightning bolts, L-shaped projectiles) cannot
 *   use `Area` for collision detection.
 * - This component provides a simple bounding rectangle interface that works for any shape,
 *   making it easy to query "where are all player attacks?" for rule systems.
 *
 * **Usage:**
 * Each attack type implements `getWorldRect()` to return a world-space bounding rectangle
 * that encompasses the attack's physical presence. This can be:
 * - A simple sprite bounding box (for simple attacks like Ember)
 * - A calculated bounding box from points (for complex shapes like Thundershock)
 * - Any other shape representation that can be bounded by a rectangle
 */

let tag = "attack"
let tagComponent = Context.tag(tag)

type customType<'t> = {
  ...CustomComponent.t<'t>,
  getWorldRect: unit => Types.rect<Kaplay.Vec2.World.t>,
}

external asAttack: customType<'t> => Types.comp = "%identity"

module Comp = (
  T: {
    type t
  },
) => {
  external getWorldRect: unit => Types.rect<Kaplay.Vec2.World.t> = "worldRect"

  /***
   * Add an Attack component to a game object.
   * @param getWorldRect Function that returns the world-space bounding rectangle of the attack.
   *                     This is called when the attack is queried (e.g., by rule systems).
   */
  let addAttack = (getWorldRect: unit => Types.rect<Kaplay.Vec2.World.t>): Types.comp => {
    asAttack({
      id: tag,
      getWorldRect,
    })
  }
}
