# Kaplay Bindings

Package: `@nojaf/rescript-kaplay`, namespace: `Kaplay`
Source types: `node_modules/kaplay/dist/doc.d.ts`

## Init & Context

Always init via `Kaplay.Context.kaplay(~initOptions=?)` with `@module("kaplay")`:
```rescript
module GameContext = {
  let k = Kaplay.Context.kaplay(~initOptions={...})
}
```

Context methods use `@send`: `k->width`, `k->setCamPos(v)`
- Return value = no `()`
- Optional labeled args = omit `()` or pass labeled args

Context helpers:
- `k.easings.<name>` = easeFunc
- `k->vec2(x,y)`, `k->vec2Zero`, `k->vec2One`, `k->vec2Left/Right/Up/Down`

## Assets & Lifecycle

Load: `k->loadSprite(name, url, ~options=?)`, `k->loadSound/Music/Font(name, url)`
Get: `k->getSprite(name): Asset.t(SpriteData.t)`
Ready: `k->Context.onLoad(() => ...)` - run after all assets loaded
Scenes: `k->scene(name, ctx => ...)`, `k->go(name, ~data=?)`, `k->goWithData(name, data)`

## Game Objects & Components

Pattern:
```rescript
module Player = {
  type t
  include Pos.Comp({type t = t})
  include Sprite.Comp({type t = t})
  
  let make = (k): t =>
    k->Context.add([addPos(k, 100., 100.), addSprite(k, "hero")])
}
```

**CRITICAL**: `include XYZ.Comp` = compile-time only. MUST also add runtime comp via `addXYZ(k, ...)` in `Context.add`, else methods exist but crash at runtime.

**Don't overuse objects**: Multiple related UI elements? Use single object with `CustomComponent.make({draw: ...})` instead of separate objects.

Common components:
- `Pos`: `addPos(k, x, y)` or `addPosFromVec2(k, v)`. Methods: `getPos`, `setPos`, `move`, `worldPos`
- `Sprite`: `addSprite(k, name, ~options=?)`. Methods: `play`, `getFrame`, `setFrame`, `getWidth/Height`
- `Area`: `addArea(k, ~options=?)`. Supports `Rect` and `Polygon` (CONVEX ONLY - no concave shapes)
- `GameObjRaw`: `onUpdate`, `destroy`, `addChild`, `getChildren`, `trigger`, `has`

Custom state:
```rescript
module Hero = {
  type t = {name: string}
  external initialState: t => Kaplay.Types.comp = "%identity"
  include Pos.Comp({type t = t})
  
  let make = (k): t =>
    k->Context.add([initialState({name: "Fred"}), addPos(k, 4., 3.)])
}
```

**NO nested object modules**: includes leak methods, causes runtime errors.

### Generic Component Access (Unit modules)

Query results = generic objects. Convert via `Unit` modules:
```rescript
let objects = k->Context.query({include_: ["movable"]})
  ->Array.filterMap(Pos.Unit.fromGameObj)
// objects: array<Pos.Unit.t>
```

Combine multiple:
```rescript
module Collidable = {
  module Unit = {
    type t
    include GameObjRaw.Comp({type t = t})
    include Pos.Comp({type t = t})
    include Area.Comp({type t = t})
    
    let fromGameObj = (obj: GameObjRaw.Unit.t): option<t> =>
      if obj->has("pos") && obj->has("area") {
        Some(Obj.magic(obj))
      } else { None }
  }
}
```

Creating Unit modules uncommon - mostly use existing or create combined modules.

### Child Origin & Transforms

Child transforms relative to parent. `addChild(parent, [...])` = local space.
See: https://v4000.kaplayjs.com/docs/api/ctx/pos/

### Local vs World Coords

Child state = local space. Convert to world:
```rescript
let candidateWorld = child->worldPos->Vec2.add(candidateLocal)
let worldRect = Math.Rect.make(k, k->vec2Zero, k->width, k->height)
if !Math.Rect.contains(worldRect, candidateWorld) { /* out of bounds */ }
```

### Nested Object Patterns

2 patterns:
1. Return components:
```rescript
module Child = {
  type t
  include GameObjRaw.Comp({type t = t})
  let makeComponents = (~x, ~y): array<comp> => [addPos(k, x, y)]
}
let child = parent->addChild(Child.makeComponents(~x=10., ~y=5.))
```

2. Pass adder (for immediate event handlers):
```rescript
module Child = {
  type t
  include GameObjRaw.Comp({type t = t})
  let make = (addToParent, ~x, ~y): t => {
    let child: t = addToParent([addPos(k, x, y)])
    child->onUpdate(() => {/* logic */})
    child
  }
}
let child = Child.make(extra => parent->addChild(extra), ~x=10., ~y=5.)
```

### Event Controllers & Cleanup

Controller variants for cancellation:
```rescript
let ctrlRef: ref<option<KEventController.t>> = ref(None)
ctrlRef := Some(obj->onUpdateWithController(() => {
  if shouldStop {
    switch ctrlRef.contents {
    | Some(ctrl) => ctrl->KEventController.cancel
    | None => ()
    }
  }
}))
```

## Events

2 variants: fire-and-forget (returns `unit`) or controller (returns `KEventController.t`).
Use `->ignore` to drop controller.

Input:
- Keyboard: `onKeyPress/Down/Release(key, cb)`
- Touch: `onTouchStart/Move/End((pos, touch) => ...)`
- Mouse: `onMousePress/Move/Release`, `k->mousePos`

Object events (via `GameObjRaw.Comp`): `onUpdate`, `onKeyDown/Press/Release`, `onDestroy`
Custom: `obj->trigger("event", arg)`, `k->on(~event, ~tag, (obj, arg) => ...)`

## Math, Tweening, Time

- `k->dt`, `k->time`
- `k->tween(~from, ~to_, ~duration, ~setValue, ~easeFunc=?)` or `tweenWithController`
- `k->wait(secs, cb)` or `waitWithController`
- `k->loop(secs, cb, ~maxLoops=?, ~waitFirst=?)` returns `TimerController.t`
- `k->randi/randf/clamp/clampFloat/deg2rad/rad2deg`

## Drawing Primitives

Direct drawing (in `onDraw`):
- `k->drawSprite({sprite, frame=?, width=?, height=?, anchor=?, ...})`
- `k->drawText({text, font=?, size=?, align=?, width=?, anchor=?, ...})`
- `k->drawRect({width, height, pos=?, color=?, outline=?, ...})`
- `k->drawLine({p1, p2, width=?, color=?, opacity=?})`
- `k->drawLines({pts, width=?, join=?, cap=?, ...})`
- `k->drawCircle/Ellipse/Polygon/Bezier/Triangle`

Many accept `renderProps`: `pos`, `scale`, `angle`, `color`, `opacity`, `fixed`, `blendMode`, `outline`

## Layers, Camera, Space

- Camera: `k->getCamPos`, `k->setCamPos(v)`, `k->toWorld(v)`, `k->toScreen(v)`
- Layers: `k->setLayers([|"bg", "game", "ui"|], "game")`, `k->getLayers()`, `k->getDefaultLayer()`
- Gravity/BG: `k->setGravity(value)`, `k->setBackground(color)`

## Typings

- Keys: `Left`, `Right`, `Up`, `Down`, `Space` (NOT strings)
- Mouse buttons: `Left`, `Right`, `Middle`
- Colors: `{r: int, g: int, b: int}`
- Single comp: `Kaplay.Types.comp`
- `Context.add([...])` expects list of `comp`, returns generic object (annotate as module's `t`)

## Calling Style

- Always use `Kaplay` namespace (NO `-` syntax)
- Chain: `value->Module.method(args)`
- Examples: `k->width`, `player->getPos |> (pos => k->setCamPos(pos))`

## Pitfalls

- Include vs Add: `include Sprite.Comp` needs `addSprite(k, ...)` in `Context.add`, else runtime crash
- No nested object modules: methods won't exist at runtime
- Controller variants: use when need cancel/unsubscribe, else `->ignore`
- Input enums: use typed constructors, NOT strings
- Use `k->Context.onLoad` before accessing loaded assets

### Polygon Collision

- Area supports CONVEX polygons only (all angles < 180°)
- Physics optimized for convex shapes
- Concave workarounds:
  - Bounding rect that encompasses shape
  - Decompose into multiple convex polygons with separate Area comps
  - Point-based collision (`hasPoint`) for lines/complex paths
  - Custom component with `getWorldRect()` for queries

## Local Docs

- `docs/content/docs/game-context.mdx` - init and context
- `docs/content/docs/game-object.mdx` - object composition, pitfalls
- `docs/content/docs/generic-component-access.mdx` - Unit modules, queries
- `packages/samples/src/*.res` - idiomatic usage examples
