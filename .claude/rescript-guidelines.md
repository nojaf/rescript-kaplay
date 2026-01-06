# ReScript v12

## Core Rules

- Latest v12 rc syntax
- NO Belt/Js modules (legacy)
- Use `JSON.t` for json
- Prefer `dict{}` pattern match over `Dict.get()`:
```rescript
// ✅ 
switch json {
| JSON.Object(dict{"sprites": JSON.Object(dict{"front_default": JSON.String(url)})}) => Some(url)
| _ => None
}
```

- Labeled args only when 2+ params same type:
```rescript
// ✅
let replace = (~input:string, ~marker:string, ~replacement:string)
// ❌
let padSpaces = (input:string, amount:int) // different types, no need
```

## Async/Promises

Use `async/await` syntax

## String Interpolation

All expressions must be string type: `` `age = ${(42)->Int.toString}` ``

## External Bindings

### @send Methods

- Return value = no `()` needed: `i->foo`
- Optional labeled args = omit arg or use labeled syntax, NEVER `()`:
```rescript
// ✅
instance->trim
instance->trim(~options=?)
// ❌
instance->trim()
```

### Module Functions

`include` brings module function symbols into scope (not visible in source)

### Namespaces

- Format: `MyNamespace.MyModule.myType`
- Internal: `MyModule-MyNamespace.myType` (compiler only, DON'T use `-` in code)
- Namespaced packages: `RescriptBun.Bun.BunFile.t` (use namespace prefix)

### Generic Type Parameters

NO F#-style generics. Inference only:
```rescript
// ✅
let id: int => int = x => x
// ❌
let id<'a> = x => x
```

## Style

- Smallest branch first (like early return) UNLESS creates unreachable patterns:
```rescript
// ✅
switch foo {
| None => 1
| Some(bar) => /* long code */ 0
}
```

## External Binding Patterns

### @new Constructor

Generates `new ClassName(...)` even if return type is record. Runtime = full JS object with methods, compile-time = record fields:
```rescript
type t = { status: int, url: string }
@new external make: unit => t = "SomeClass"
let obj = make() // Runtime: SomeClass instance, compile-time: record
```

### @module Scoping

`@module("name")` imports from npm package. Without it, looks in global scope:
```rescript
@new @module("pocketbase")
external make: unit => t = "ClientResponseError" // from npm
@new external make: unit => t = "File" // from global
```

### Record Type vs Abstract with @new

Record = convenient field access:
```rescript
type t = { status: int }
@new external make: unit => t = "Class"
let s = obj.status // direct access
```

Abstract + @get/@set = explicit:
```rescript
type t
@get external status: t => int = "status"
```

### Optional Record Fields

Use `?` syntax:
```rescript
type opt = {
  width: int,
  background?: {r: int, g: int, b: int},
}
```

## CLI

NEVER run rescript build. User runs `bunx rescript watch` in terminal. Subsequent builds fail if watch mode active.
