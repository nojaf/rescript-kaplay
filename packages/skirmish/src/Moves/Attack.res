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

type customType<'t> = {
  ...CustomComponent.t<'t>,
  getWorldRect: @this ('t => Types.rect<Vec2.World.t>),
}

external asAttack: customType<'t> => Types.comp = "%identity"

module Comp = (
  T: {
    type t
  },
) => {
  @send
  external getWorldRect: T.t => Types.rect<Kaplay.Vec2.World.t> = "getWorldRect"

  let getClosestCorner = (
    attack: T.t,
    k: Context.t,
    ~pokemonPosition: Vec2.World.t,
  ): Vec2.World.t => {
    let attackRect = attack->getWorldRect
    let attackCenter =
      attackRect.pos->Vec2.World.add(
        k->Context.vec2World(attackRect.width / 2., attackRect.height / 2.),
      )
    let isAttackOnTheLeftOfPokemon = attackCenter.x < pokemonPosition.x
    let isAttackOnTopOfPokemon = attackCenter.y < pokemonPosition.y
    let leftX = attackRect.pos.x
    let rightX = attackRect.pos.x + attackRect.width
    let topY = attackRect.pos.y
    let bottomY = attackRect.pos.y + attackRect.height

    switch (isAttackOnTheLeftOfPokemon, isAttackOnTopOfPokemon) {
    | (true, true) => k->Context.vec2World(rightX, bottomY)
    | (true, false) => k->Context.vec2World(rightX, topY)
    | (false, true) => k->Context.vec2World(leftX, bottomY)
    | (false, false) => k->Context.vec2World(leftX, topY)
    }
  }

  /***
   * Add an Attack component to a game object.
   * @param getWorldRect Function that returns the world-space bounding rectangle of the attack.
   *                     This is called when the attack is queried (e.g., by rule systems).
   */
  let addAttack = (getWorldRect: @this (T.t => Types.rect<Kaplay.Vec2.World.t>)): array<
    Types.comp,
  > => [
    asAttack({
      id: tag,
      getWorldRect,
    }),
    Context.tag(tag),
  ]
}

module Unit = {
  type t
  include GameObjRaw.Comp({type t = t})
  include Comp({type t = t})

  let fromGameObj = (obj: GameObjRaw.Unit.t): option<t> => {
    if obj->GameObjRaw.Unit.has(tag) {
      Some(Obj.magic(obj))
    } else {
      None
    }
  }
}
